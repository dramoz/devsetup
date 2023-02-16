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
TB Class
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
from sim_modules.sim_helpers import cycle_N_generator, high_low_cycles_generator, TEST_TYPE, time_clk_hr_min_sec

from sim_modules.tb_uut_class import TestBenchBase, UUT_Base

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
class top_module_UUT(UUT_Base):
  def __init__(self, from_env=False, log_level=logging.INFO, PARAM_NM=0):
    """
    Place holder for UUT info, ports, parameters, ...
    """
    params = locals().copy()
    del params['self']
    del params['__class__']
    params['toplevel'] = "qeng_revb_armif_test_h2f_lw_mux"
    params['rtl_sources'] = None
    super().__init__(**params)
    
# -----------------------------------------------------------------------------
class h2f_lw_mux_tb(TestBenchBase):
  def __init__(self,
      dut,
      tb_param=None,
      sim_param=None,
      stop_on_error=True,
  ):
    # ------------------------------------------------------------
    args = locals().copy()
    del args['self']
    del args['__class__']
    args['dut_params_class'] = top_module_UUT
    
    super().__init__(**args)
    self.add_reset(dut.resetn, level=SignalLvl.ACTIVE_LOW)
    self.add_clock(dut.clk, cycle_ns=10)
    
  # ==================================================================
  @classmethod
  def check_idle_blks(cls):
    return []
  @classmethod
  def check_bkpressure_blks(cls):
    return []
  
  # ------------------------------------------------------------
  async def start_monitors(self):
    assert False, "Not implemented..."
  
  # ==================================================================
  # Driver async methods
  # ------------------------------------------------------------
  async def start_drivers(self):
    assert False, "Not implemented..."
  