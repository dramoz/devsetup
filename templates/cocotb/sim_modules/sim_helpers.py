#####################################################################################
#  File: sim_helpers.py
#  Copyright (c) 2022 Eidetic Communications Inc.
#  All rights reserved.
#  This license message must appear in all versions of this code including
#  modified versions.
#  BSD 3-Clause
####################################################################################
#  Overview:
"""
Common methods for TB sim and data generation
"""

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

from multiprocessing.sharedctypes import Value
import sys, os
import random
import itertools
import logging
from pathlib import Path
from enum import Enum, auto, unique

# -----------------------------------------------------------------------------
import cocotb
from cocotb.utils import get_sim_time
from cocotb.triggers import Timer, First, Edge, RisingEdge, with_timeout, ClockCycles, Event
from cocotb.result import SimTimeoutError

# -----------------------------------------------------------------------------
# Local modules
_workpath = Path(__file__).resolve().parent
# This lvl/dir
sys.path.append(str(_workpath))
# Up-one lvl/dir
sys.path.append(str(_workpath.parent))
# -----------------------------------------------------------------------------
sim_units = 'ns'

# -----------------------------------------------------------------------------
def time_clk_hr_min_sec(t):
  if t > 1:
    hr = t // (24*3600)
    t %= 3600
    m  = t // 60
    s = t % 60
    
    return f"{int(hr):02}:{int(m):02}:{int(s):02} (h:m:s)"
    
  else:
    return f"{t:.4} s"
  
# -----------------------------------------------------------------------------
def cycle_N_generator(N):
  return (int( not (x % (2*N)) >= N) for x in itertools.count(1))
  
def high_low_cycles_generator(lst, st=0, init=[]):
  lst_cyc = []
  for cnt in lst:
    lst_cyc += [st%2]*cnt
    st += 1
    
  return itertools.chain(init, itertools.cycle(lst_cyc))

def get_gap_generator(gap_vl):
  if gap_vl in {None, 0, [0]}:
    return None
  
  if isinstance(gap_vl, int):
    return cycle_N_generator(gap_vl)
  
  else:
    if len(gap_vl)==3:
      idle_start = gap_vl[2]
      gap_vl = gap_vl[0:2]
    else:
      idle_start = 10
    
    return high_low_cycles_generator(lst=gap_vl, init=[1]*idle_start)
  
# ---------------------------------------------
@unique
class AutoName(Enum):
  def _generate_next_value_(name, start, count, last_values):
    return name

class TB_Test_Mode(AutoName):
  DEBUG = auto()
  SELF_CHECK = auto()
  SANITY = auto()
  FULL = auto()
  REGRESSION = auto()
  COVERAGE = auto()
  
TEST_TYPE = TB_Test_Mode[os.environ.get("TEST_TYPE", "SANITY")]
# -----------------------------------------------------------------------------
BLKS_SIZE = 4096
DATA_BYTES = int(os.environ.get('DATA_BYTES', 256//8))
# -----------------------------------------------------------------------------
class DataPkt():
  unique_vl = 1
  
  @unique
  class Mode(Enum):
    RND = 0
    INC = 1
    DEC = 2
    ZEROS = 3
    ONES = 4
    UNIQUE = 5
    UNIQUE_GLB = 6
    INC_PATTERN = 7
    FIX_PATTERN = 8
    AA = 0xaa
    A5 = 0xa5
    C3 = 0xc3
    
  def __init__(self, word_length, data_type=None, arg_vl=0, seed=1234) -> None:
    self.seed = seed
    self.arg_vl = arg_vl
    self.wl = word_length
    self.next_vl = 0
    
    if data_type is None:
      data_type = os.environ.get('data_type', None)
    
    if data_type is None:
      if TEST_TYPE == TB_Test_Mode.DEBUG:
        data_type = DataPkt.Mode.INC
        
      elif TEST_TYPE == TB_Test_Mode.SELF_CHECK:
        data_type = DataPkt.Mode.INC
        
      elif TEST_TYPE == TB_Test_Mode.FULL:
        data_type = DataPkt.Mode.RND
        
      elif TEST_TYPE == TB_Test_Mode.SANITY:
        data_type = DataPkt.Mode.INC
        
      elif TEST_TYPE == TB_Test_Mode.REGRESSION:
        data_type = DataPkt.Mode.RND
        
      elif TEST_TYPE == TB_Test_Mode.COVERAGE:
        data_type = DataPkt.Mode.RND
      else:
        data_type = DataPkt.Mode.RND
    else:
      data_type = DataPkt.Mode[data_type]
    
    self.data_type = data_type
    
# -----------------------------------------------------------------------------
  def get_data(self, size):
    if self.data_type == DataPkt.Mode.RND:
      if self.arg_vl:
        saved_state = random.getstate()
        random.seed(self.seed)
        self.seed = random.randrange(1, sys.maxsize)
        data = bytearray([random.randint(0, 255) for _ in range(size)])
        random.setstate(saved_state)
      else: 
        data = bytearray(os.urandom(size))
    
    elif self.data_type == DataPkt.Mode.INC:
      data = bytearray([x % 256 for x in range(self.next_vl, self.next_vl+size)])
      self.next_vl += size
      
    elif self.data_type == DataPkt.Mode.DEC:
      data = bytearray([x % 256 for x in range(self.next_vl+size, self.next_vl, -1)])
      self.next_vl += size
      
    elif self.data_type == DataPkt.Mode.ZEROS:
      data = bytearray([0x00] * size)
      
    elif self.data_type == DataPkt.Mode.ONES:
      data = bytearray([0xff] * size)
    
    elif self.data_type == DataPkt.Mode.UNIQUE:
      data = bytearray()
      while len(data) < size:
        data += self.next_vl.to_bytes(self.wl, 'little')
        self.next_vl = (self.next_vl + 1) % (2**(8*self.wl))
        
    elif self.data_type == DataPkt.Mode.UNIQUE_GLB:
      data = bytearray()
      while len(data) < size:
        data += DataPkt.unique_vl.to_bytes(self.wl, 'little')
        DataPkt.unique_vl = (DataPkt.unique_vl + 1) % (2**(8*self.wl))
        
    elif self.data_type == DataPkt.Mode.INC_PATTERN:
      data = bytearray()
      while len(data) < size:
        data += bytearray([self.next_vl] * self.wl)
        DataPkt.unique_vl = (self.next_vl + 1) % (2**8)
        
    else:
      # DataPkt.Mode.PATTERNs
      data = bytearray([self.arg_vl] * size)
      
    return data[:size]
  
# -----------------------------------------------------------------------------
class SyncProcess:
  _ids = 0
  # ------------------------------------------------------------
  def __init__(self, id=None) -> None:
    if id is None:
      id = str(SyncProcess._ids)
      SyncProcess._ids += 1
    
    self.event = Event(name=id)
    self._log = logging.getLogger("tb")
    self.syncs = []
    
  # ------------------------------------------------------------
  async def _delay(self, time, units):
    self._log.tb_dbg(f"sync::delay::start {time}{units}")
    await Timer(time=time, units=units)
    self._log.tb_dbg(f"sync::delay::end {time}{units}")
  
  async def _sim_time(self, sim_time, units):
    self._log.tb_dbg(f"sync::sim_time::start {sim_time}{units}")
    curr_sim_time = get_sim_time(units=units)
    if sim_time > curr_sim_time:
      await Timer(time=sim_time-curr_sim_time, units=units)
    self._log.tb_dbg(f"sync::sim_time::end {sim_time}{units}")
    
  async def _clk_cycles(self, clock, cycles):
    self._log.tb_dbg(f"sync::clk_cycles::start {clock.name}x{cycles}")
    await ClockCycles(clock, cycles)
    self._log.tb_dbg(f"sync::clk_cycles::end {clock.name}x{cycles}")
  
  async def _signal_vl(self, signal, value, clock, timeout, units):
    self._log.tb_dbg(f"sync::signal_vl::start {signal.name}={value} (clk:{clock}, timeout: {timeout}{units})")
    if timeout is not None:
      max_sim_time = get_sim_time(units=units) + timeout
      
    while signal.value != value:
      if timeout is not None and max_sim_time < get_sim_time(units=units):
          raise ValueError(f"timeout while waiting for {signal.name}={value}")
      
      if clock is not None:
        await RisingEdge(self.clock)
      else:
        if timeout is not None:
          await with_timeout(Edge(signal), timeout_time=timeout, timeout_unit=units)
        else:
          await Edge(signal)
    
    self._log.tb_dbg(f"sync::signal_vl::end {signal.name}={value} (clk:{clock}, timeout: {timeout}{units})")
    
  async def _event(self, event, timeout, units):
    self._log.tb_dbg(f"sync::signal_vl::start {event.name} (timeout: {timeout}{units}")
    if not event.is_set():
      if timeout is not None:
        await with_timeout(event.wait(), timeout_time=timeout, timeout_unit=units)
      else:
        await event.wait()
      event.clear()
      
    self._log.tb_dbg(f"sync::signal_vl::end {event.name} (timeout: {timeout}{units})")
  
  # ------------------------------------------------------------
  def add_delay(self, delay, units='ns'):
    self.syncs.append( (self._delay, {'time':delay, 'units':units}) )
  
  def wait_until_sim_time(self, time, units):
    self.syncs.append( (self._sim_time, {'sim_time':time, 'units':units}) )
  
  def wait_clock_cycles(self, clock, cycles):
    self.syncs.append( (self._clk_cycles, {'clock':clock, 'units':cycles}) )
  
  def wait_signal_value(self, signal, value, clock=None, timeout=None, units=None):
    self.syncs.append( (self._signal_vl, {'signal':signal, 'value':value, 'clock':clock, 'timeout':timeout, 'units':units}) )
  
  def wait_event(self, event, timeout=None, units=None):
    self.syncs.append( (self._event, {'event':event, 'timeout':timeout, 'units':units}) )
    
  # ------------------------------------------------------------
  def __call__(self):
    cocotb.start_soon(self.run())
    return self.event
  
  async def run(self):
    self._log.tb_dbg(f"sync::all::start #{len(self.syncs)} (proc: {self.event.name})")
    for sync, args in self.syncs:
      await sync(**args)
      
    # --------------------------------------------------
    # Launch process / or fire event
    self._log.tb_dbg(f"sync::all::done event({self.event.name}).set()")
    self.event.set()
  
# -----------------------------------------------------------------------------
async def with_timeout_msg(trigger, msg, timeout_time, timeout_unit="step"):
    log = logging.getLogger("cocotb.tb")
    timeout_timer = Timer(timeout_time, timeout_unit)
    res = await First(timeout_timer, trigger)
    if res is timeout_timer:
        log.error(f"TIMEOUT: {msg}")
        raise SimTimeoutError
    else:
        return res
    