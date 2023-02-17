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
from cocotb.regression import TestFactory

# -----------------------------------------------------------------------------
# Internal modules
_workpath = Path(__file__).resolve().parent
sys.path.append(str(_workpath))
sys.path.append(str(_workpath.parent))

from sim_modules.run_cocotb_sim import run_cocotb_sim
from sim_modules.pytest_methods import pytest_purge_tests, TestFactoryWithNames, conditional_parametrize
from sim_modules.pytest_methods import set_and_run_sim, set_env_args, ids, ids_enum

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
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
async def test_name_func(dut, **uut_params):
  pass
  
# -----------------------------------------------------------------------------
# Test(s) parameters
# -------------------------------------------------------------------
# PyTest(s) parameters

# -------------------------------------------------------------------
# CoCoTB func_call args

# **********************************************

# **********************************************
# Run default sanity test
tests_list = []
from_pytest = []

# GAP values XOR idle/backpressure_generators
gap_vl = [0, 1, 16]

# -----------------------------------------------------------------------------
if cocotb.SIM_NAME:
  # ---------------------------------------------
  tests = {
    # ---------------------------------------------
    'test_name': {
      'test': test_name_func,
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
PARAM_NM_VL_LST = [0]
tb_class = None
uut_class = None

@pytest.mark.parametrize("PARAM_NM", PARAM_NM_VL_LST, ids=lambda x:str(x))
@conditional_parametrize(from_pytest, "PARAM_NM", PARAM_NM_VL_LST, ids=ids('nick_nm'))
def test_sanity(request, PARAM_NM):
    set_and_run_sim(pymodule=Path(__file__).stem, workpath=Path(__file__).resolve().parent, tests=tests_list, tb_class=tb_class, uut_param_class=uut_class, **locals())

# -----------------------------------------------------------------------------
# Invoke test
if __name__ == '__main__':
    run_n_times = int(os.getenv("RUN_N", 1))
    total_sims = math.prod( [len(arg) for arg in [PARAM_NM_VL_LST, PARAM_NM_VL_LST, PARAM_NM_VL_LST]] ) * run_n_times
    for inx, (PARAM_NM, PARAM_NM, PARAM_NM) in enumerate( itertools.product(PARAM_NM_VL_LST, PARAM_NM_VL_LST, PARAM_NM_VL_LST) ):
        test_parameters = {
            'PARAM_NM': PARAM_NM_VL_LST,
            'PARAM_NM': PARAM_NM_VL_LST,
            'PARAM_NM': PARAM_NM_VL_LST,
        }
        logging.critical(f"Running with SIM.PARAMS[{inx}/{total_sims}]: {test_parameters}")
        # Run sim
        PARAMS_LST = [None]
        for _ in range(run_n_times):
            dut = uut_class(**PARAMS_LST)
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
