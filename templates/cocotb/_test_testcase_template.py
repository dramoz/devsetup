#####################################################################################
#  Copyright (c) 2023 Eidetic Communications Inc.
#  All rights reserved.
#  This license message must appear in all versions of this code including
#  modified versions.
#  BSD 3-Clause
####################################################################################
#  Overview:
"""
CoCoTB TB base
"""

import itertools
import logging
import math
import os
import pytest
import sys
from pathlib import Path

import cocotb
from cocotb.triggers import ClockCycles, RisingEdge, FallingEdge, Timer, ReadOnly, ReadWrite
from cocotb.regression import TestFactory

# -----------------------------------------------------------------------------
# Internal modules
_workpath = Path(__file__).resolve().parent
sys.path.append(str(_workpath))
sys.path.append(str(_workpath.parent))

from sim_modules.cocotb_methods import with_timeout_msg
from sim_modules.run_cocotb_sim import run_cocotb_sim
from sim_modules.pytest_methods import pytest_purge_tests, TestFactoryWithNames, conditional_parametrize
from sim_modules.pytest_methods import set_and_run_sim, set_env_args, ids, ids_enum

from top_tb_class import top_module_UUT, top_module_TB

# -----------------------------------------------------------------------------
# Info
__author__ = 'Danilo Ramos'
__copyright__ = 'Copyright (c) 2023 Eidetic Communications Inc.'
__credits__ = ['Danilo Ramos']
__license__ = 'BSD 3-Clause'
__version__ = "0.0.1"
__maintainer__ = 'Danilo Ramos'
__email__ = 'danilo.ramos@eideticom.com'

# __status__ = ["Prototype"|"Development"|"Production"]
__status__ = "Prototype"

# -----------------------------------------------------------------------------
as_pytest = int(os.getenv("AS_PYTEST", 0)) == 1
as_factory = int(os.getenv("AS_FACTORY", 0)) == 1
requested_test = os.getenv("REQUESTED_TESTS", "")
# -----------------------------------------------------------------------------
async def test_clk_free_run(dut, **uut_params):
  tb = top_module_TB(dut)
  
  # ---------------------------------------------
  tb._log.sim_msg(80*'-')
  tb._log.sim_msg('Start test...')
  await tb.start_test(start_monitors=False, start_drivers=False)
  #await tb.start_monitors()
  #await tb.start_drivers()
  
  # ---------------------------------------------
  # r = await with_timeout_msg(msg="process testing", trigger=awaitable_process())
  await ClockCycles(tb.main_clk, 10)
  
  # ---------------------------------------------
  await tb.done()
  tb._log.sim_msg('Test(s) passed')
  tb._log.sim_msg(80*'-')
  
# **********************************************
# -----------------------------------------------------------------------------
# Test(s) parameters

# -------------------------------------------------------------------
# PyTest(s) parameters

# **********************************************
# -------------------------------------------------------------------
# CoCoTB func_call args
# -----------------------------------------------------------------------------
if not as_pytest and not as_factory:
  # For manual testing, set parameters here
  # make clean; script -c "WAVES=1 LOGLEVEL=INFO MODULE=test_tc_name PARAM_NM=512 RANDOM_SEED=1234 SIM=verilator make"
  @cocotb.test()
  async def cocotb_single_test_run(dut):
    #set_eng_as = {}
    await test_clk_free_run(dut=dut, PARAM_NM=0)
  
# **********************************************

# **********************************************
# Run default sanity test
tests_list = ["free_run_test"]
from_pytest = []

# GAP values XOR idle/backpressure_generators
gap_vl = [0, 1, 16]

# -----------------------------------------------------------------------------
if cocotb.SIM_NAME and (as_pytest or as_factory):
  # ---------------------------------------------
  tests = {
    # ---------------------------------------------
    'free_run_test': {
      'test': test_clk_free_run,
      'args': {
        
      }
    },
  }
  # -----------------------------------------------------
  if gap_vl is not None:
    for test_data in tests.values():
      test_data['args']['gap_vl'] = gap_vl
  # -----------------------------------------------------
  tests = pytest_purge_tests(tests, from_pytest, tests_list)
  for postfix, params in tests.items():
    factory = TestFactoryWithNames(params['test'])
    for arg_nm, opts_lst in params['args'].items():
      factory.add_option(name=arg_nm, optionlist=opts_lst)
    
    factory.generate_tests(postfix='_'+postfix)

# -----------------------------------------------------------------------------
# pytest
# -----------------------------------------------------------------------------
PARAM_NM0_VL_LST = [0]
PARAM_NM1_VL_LST = [1]

@pytest.mark.parametrize("PARAM_NM0", PARAM_NM0_VL_LST, ids=lambda x:str(x))
@conditional_parametrize(from_pytest, "PARAM_NM1", PARAM_NM1_VL_LST, ids=ids('nick_nm'))
def test_sanity(request, PARAM_NM0, PARAM_NM1):
  set_and_run_sim(pymodule=Path(__file__).stem, workpath=Path(__file__).resolve().parent, tests=tests_list, tb_class=top_module_TB, uut_param_class=top_module_UUT, **locals())

# -----------------------------------------------------------------------------
# Invoke test
if __name__ == '__main__':
  run_n_times = int(os.getenv("RUN_N", 1))
  total_sims = math.prod( [len(arg) for arg in [PARAM_NM0_VL_LST, PARAM_NM0_VL_LST]] ) * run_n_times
  for inx, (PARAM_NM, PARAM_NM0) in enumerate( itertools.product(PARAM_NM0_VL_LST, PARAM_NM1_VL_LST) ):
    test_parameters = {
      'PARAM_NM0': PARAM_NM,
      'PARAM_NM1': PARAM_NM0,
    }
    logging.info(f"Running with SIM.PARAMS[{inx}/{total_sims}]: {test_parameters}")
    
    # Run sim
    # Opt1:
    for _ in range(run_n_times):
      dut = top_module_UUT(from_env=True)
      run_cocotb_sim(
        module=Path(__file__).stem,
        top_level=dut.toplevel,
        test_name=Path(__file__).stem,
        include_dirs=['../../../../../rtl/'],
        hdl_sources=dut.verilog_sources,
        parameters=dut.parameters,
        testcase=None,
        workpath=Path(__file__).resolve().parent,
        extra_env=test_parameters,
      )
      
    # Opt2:
    for _ in range(run_n_times):
      dut = top_module_UUT(from_env=False, **test_parameters)
      run_cocotb_sim(
        module=Path(__file__).stem,
        top_level=dut.toplevel,
        test_name=Path(__file__).stem,
        include_dirs=['../../../../../rtl/'],
        hdl_sources=dut.verilog_sources,
        parameters=dut.parameters,
        testcase=None,
        workpath=Path(__file__).resolve().parent,
        extra_env=None,
      )
  
