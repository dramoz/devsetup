#####################################################################################
#  File: tb_class.py
#  Copyright (c) 2022 Eidetic Communications Inc.
#  All rights reserved.
#  This license message must appear in all versions of this code including
#  modified versions.
#  BSD 3-Clause
####################################################################################
# Overview:
"""
TB Base Class
"""
# -----------------------------------------------------------------------------
import sys, os
import logging
import time
from pathlib import Path
from enum import Enum, unique
# -----------------------------------------------------------------------------
import cocotb
import cocotb.ANSI as ANSI
from cocotb.clock import Clock
from cocotb.utils import get_sim_time
from cocotb.triggers import Edge, RisingEdge, FallingEdge, Timer, ClockCycles
# -----------------------------------------------------------------------------
# Local modules
_workpath = Path(__file__).resolve().parent
# This lvl/dir
sys.path.append(str(_workpath))
# Up-one lvl/dir
sys.path.append(str(_workpath.parent))

from logger import add_logging_lvl
from sim_helpers import cycle_N_generator, high_low_cycles_generator, TEST_TYPE, time_clk_hr_min_sec

# -----------------------------------------------------------------------------
# Info
__author__ = 'Danilo Ramos'
__copyright__ = 'Copyright (c) 2022 Eidetic Communications Inc.'
__credits__ = ['Danilo Ramos']
__license__ = 'BSD 3-Clause'
__version__ = "0.0.1"
__maintainer__ = 'Danilo Ramos'
__email__ = 'danilo.ramos@eideticom.com'

# __status__ = ["Prototype"|"Development"|"Production"]
__status__ = "Prototype"

# -----------------------------------------------------------------------------
@unique
class SignalLvl(Enum):
  ACTIVE_LOW  = 0
  ACTIVE_HIGH = 1

# -----------------------------------------------------------------------------
class UUT_Base:
  # ==================================================================
  def __init__(self,
    toplevel,
    rtl_sources=None,
    from_env=False, log_level=logging.INFO,
    **kwargs
  ):
    self._log = logging.getLogger("uut")
    self._log.setLevel(log_level)
    
    self.toplevel = toplevel
    if rtl_sources is None:
      rtlfiles_lst = Path(os.environ.get('TB_PATH', '.') + '/rtlfiles.lst')
      self.verilog_sources = [fl for fl in rtlfiles_lst.read_text().split('\n') if fl]
      
    self.parameters = kwargs.copy()
    
    if from_env:
      for param, vl in self.parameters.items():
        self.parameters[param] = int(os.getenv(param, str(vl)))
        
    for param, vl in self.parameters.items():
      self.__setattr__(param, vl)
    
    self._log.critical(f"DUT[{self.toplevel}] parameters: {self.parameters}")
    
# -----------------------------------------------------------------------------
class TestBenchBase:
  _idle_blks = {}
  _bkpressure_blks = {}
  _log = logging.getLogger("cocotb.tb")
  
  # ==================================================================
  def __init__(self,
    dut, dut_params_class, dut_params_args,
    stop_on_error=True, eos_on_error=(1, 'us')
  ):
    """
    Setup cocotb TB
    """
    # ------------------------------------------------------------
    args = locals().copy()
    del args['self']
    # ------------------------------------------------------------
    # Logging
    # ------------------------------------------------------------
    # TB log messages
    add_logging_lvl(name="TB_MSG",  level=logging.WARNING + 1, color=ANSI.BLUE_FG)
    add_logging_lvl(name="SIM_MSG", level=logging.WARNING + 2, color=ANSI.GREEN_FG)
    add_logging_lvl(name="TB_DBG",  level=logging.INFO + 1, color=ANSI.BLUE_FG  + ANSI.WHITE_BG)
    add_logging_lvl(name="SIM_DBG", level=logging.INFO + 2, color=ANSI.BLACK_FG + ANSI.WHITE_BG)
    
    # ------------------------------------------------------------
    self._loglevel = os.environ.get("LOGLEVEL", "INFO")
    self._models_loglevel = os.environ.get("MODELS_LOGLEVEL", "WARNING")
    self._log.warning(f'Setting TB (CoCoTB Logger) log level to "{self._loglevel}", others to "{self._models_loglevel}"')
    loggers = [logging.getLogger(name) for name in logging.root.manager.loggerDict]
    for log in loggers:
      if "cocotb" not in log.name:
        self._log.critical(f"Setting logger {log.name} to LOG_LEVEL:{self._models_loglevel}")
        log.setLevel(self._models_loglevel)
      else:
        if self._models_loglevel not in ["DEBUG", "INFO"]:
          log.setLevel("INFO")
        else:
          log.setLevel(self._models_loglevel)
    
    self._log.setLevel(self._loglevel)
    
    # ------------------------------------------------------------
    # DUT signals
    self.dut = dut
    if dut_params_args is None:
      dut_params_args = {}
    if not 'from_env' in dut_params_args:
      dut_params_args['from_env'] = True
    if not 'log_level' in dut_params_args:
      dut_params_args['log_level'] = self._loglevel
    
    self.dut_params = dut_params_class(**dut_params_args)
    
    # ------------------------------------------------------------
    # TB
    self.stop_on_error = stop_on_error
    self.eos_on_error  = eos_on_error
    self._dump_data = False
    self.rsts = {}
    self.clks = {}
    
    # ----------------------------------------
    # DRV(s)/MON(s) Done Event(s)
    self.sim_done = False
    self.drv_mon_done = []
    
  def add_reset(self, signal, level):
    if not self.rsts:
      self.main_rst = signal
    self.rsts[signal._name] = (signal, level)
  
  def add_clock(self, signal, cycle_ns):
    if not self.clks:
      self.main_clk = signal
    self.clks[signal._name] = (signal, cycle_ns)
  
  # ==================================================================
  @classmethod
  def check_idle_blks(cls):
    return []
  @classmethod
  def check_bkpressure_blks(cls):
    return []
  
  @classmethod
  def get_gap_generators(cls, gap_vl, idle_blks=None, skip_idle_blks=None, idle_blks_gap_vl=None, bkpressure_blks=None, skip_backpressure_blks=None, bkpressure_blks_gap_vl=None):
    if idle_blks is None:
      idle_blks = cls.check_idle_blks()
    if bkpressure_blks is None:
      bkpressure_blks = cls.check_bkpressure_blks()
    
    if skip_idle_blks is not None:
      idle_blks = [blk for blk in idle_blks if blk not in skip_idle_blks]
    if skip_backpressure_blks is not None:
      bkpressure_blks = [blk for blk in bkpressure_blks if blk not in skip_backpressure_blks]
    
    # Setup gap mode/value per blk
    if idle_blks_gap_vl is None:
      idle_generators = { blk:gap_vl for blk in idle_blks }
    
    elif isinstance(idle_blks_gap_vl, int):
      idle_generators = { blk:idle_blks_gap_vl for blk in idle_blks }
    
    else:
      idle_generators = { blk:idle_blks_gap_vl[blk] if blk in idle_blks_gap_vl else gap_vl for blk in idle_blks }
      
    if bkpressure_blks_gap_vl is None:
      backpressure_generators = { blk:gap_vl for blk in idle_blks }
    
    elif isinstance(bkpressure_blks_gap_vl, int):
      backpressure_generators = { blk:bkpressure_blks_gap_vl for blk in idle_blks }
    
    else:
      backpressure_generators = { blk:bkpressure_blks_gap_vl[blk] if blk in bkpressure_blks_gap_vl else gap_vl for blk in idle_blks }
    
    return idle_generators, backpressure_generators
    
  # ------------------------------------------------------------
  def set_idle_generators(self, generators=None):
    if generators:
      self._log.warning(f"Enable idle generators for: {list(generators.keys())}")
      for nm, generator in generators.items():
        self._idle_blks[nm].set_pause_generator(generator)
    
  # ------------------------------------------------------------
  def set_backpressure_generators(self, generators=None):
    if generators:
      self._log.warning(f"Enable backpressure generators for: {list(generators.keys())}")
      for nm, generator in generators.items():
        self._bkpressure_blks[nm].set_pause_generator(generator)
    
  # ==================================================================
  # Monitors async methods
  # ------------------------------------------------------------
  async def signal_monitor(self, signal, rising_edge=True):
    self._log.warning(f'Signal Monitor started for {signal._name} {"Rising Edge" if rising_edge == True else "Falling Edge"}')
    while True:
      if rising_edge==1:
        await RisingEdge(signal)
      else:
        await FallingEdge(signal)
      
      self._log.error(f'{signal._name} triggered with: [ {signal._name} == {signal.value}]')
      if self.stop_on_error:
        await Timer(*self.eos_on_error)
        assert False, f'Un-expected {signal._name} detected!'
    
  async def bus_monitor(self, signal, value):
    self._log.warning(f'Bus Monitor started for {signal._name} == {value}')
    while True:
      await Edge(signal)
      if signal.value == value:
        self._log.error(f'{signal._name} error triggered with: [ {signal._name} == {signal.value}]')
        if self.stop_on_error:
          await Timer(*self.eos_on_error)
          assert False, f'Un-expected {signal._name} value {signal.value} detected!'
    
  # ------------------------------------------------------------
  async def start_monitors(self):
    assert False, "Not implemented..."
  
  # ==================================================================
  # Driver async methods
  # ------------------------------------------------------------
  async def start_drivers(self):
    assert False, "Not implemented..."
  
  # ------------------------------------------------------------
  async def sim_timeout_event(self, max_sim_time):
    self._log.critical(f"WDT set to {max_sim_time[0]} {max_sim_time[1]}")
    await Timer(max_sim_time[0], units=max_sim_time[1])
    self._log.critical(f"Maximum simulation time reached: {max_sim_time[0]} {max_sim_time[1]}")
    assert False, "WDT Fail"
    
  # ------------------------------------------------------------
  async def reset(self, cycles):
    self._log.tb_msg("Setting reset(s) signals...")
    for rst, lvl in self.rsts.values():
      lvl_vl = 0 if lvl == SignalLvl.ACTIVE_LOW else 1
      self._log.tb_msg(f"{rst._name}[{lvl.name}] = {lvl_vl}")
      rst.value = lvl_vl
    
    self._log.sim_msg(f"Waiting {self.main_clk._name} {cycles} cycles...")
    await ClockCycles(self.main_clk, cycles)
    self._log.tb_msg("Clearing reset(s) signals...")
    for rst, lvl in self.rsts.values():
      lvl_vl = 1 if lvl == SignalLvl.ACTIVE_LOW else 0
      self._log.tb_msg(f"{rst._name}[{lvl.name}] = {lvl_vl}")
      rst.value = lvl_vl
    
    self._log.tb_msg("Out of reset")
  
  # ------------------------------------------------------------
  async def start_clocks(self):
    self._log.info("Starting CLK(s)")
    for signal, cycle in self.clks.values():
      self._log.tb_msg(f"Creating clock: {signal._name} - {1/(cycle*1e-9*1e6)} MHz ({cycle} ns)")
      cocotb.start_soon(Clock(signal=signal, period=cycle, units="ns").start())
  
  # ------------------------------------------------------------
  async def start_test(
      self,
      start_clk=True,
      issue_reset=True, reset_cycles=10,
      sim_units='us',
      testcase=None,
      max_sim_time=None,
      start_monitors=True,
      start_drivers=True,
      **kwargs
    ):
    self.sys_start_time = time.time()
    
    self._log.info("Setting TB and UUT (POR)")
    self.testcase = testcase
    # CLK(s) and RST(s)
    if start_clk:
      await self.start_clocks()
      
    if issue_reset:
      await self.reset(cycles=reset_cycles)
    elif start_clk:
      await ClockCycles(self.main_clk, reset_cycles)
    else:
      await Timer(1, units=sim_units)
    
    # ----------------------------------------
    self.start_time = round(get_sim_time(sim_units))
    self.sim_units = sim_units
    
    if start_monitors:
      await self.start_monitors(**kwargs)
    if start_drivers:
      await self.start_drivers(**kwargs)
    
    # ----------------------------------------
    # Report TC after enumerate
    self._log.tb_msg(f'TEST_TYPE: {TEST_TYPE}, start_time: {self.start_time} {self.sim_units}')
    if self.testcase is not None:
      self._log.tb_msg(f'Testcase: {self.testcase}')
    
    if max_sim_time is not None:
      cocotb.fork(self.sim_timeout_event(max_sim_time))
    
  # ------------------------------------------------------------
  async def done(self, eos_delay=None):
    self._log.sim_msg("Waiting for drivers/monitors to finish transaction(s)")
    for evnt in self.drv_mon_done:
      await evnt.wait()
      self._log.sim_msg(f"{evnt.data} done (nm:{evnt.name})")
      evnt.clear()
      
    self.sim_done = True
    self._log.tb_msg("Simulation completed")
    if eos_delay is not None:
      self._log.tb_msg(f"EOS in {eos_delay[0]}{eos_delay[1]} ")
      await Timer(*eos_delay)
    
    self.sys_end_time = time.time()
    self._log.tb_msg(f"Simulation completed in {time_clk_hr_min_sec(self.sys_end_time-self.sys_start_time)}")
  