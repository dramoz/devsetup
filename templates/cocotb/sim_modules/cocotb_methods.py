#####################################################################################
#  File: eidma_dma_top_cocotb_pytest.py
#  Copyright (c) 2021 Eidetic Communications Inc.
#  All rights reserved.
#  This license message must appear in all versions of this code including
#  modified versions.
#  BSD 3-Clause
####################################################################################
#  Overview:
"""

"""

# -----------------------------------------------------------------------------
# Info
__author__ = 'Danilo Ramos'
__copyright__ = 'Copyright (c) 2021 Eidetic Communications Inc.'
__credits__ = ['Danilo Ramos']
__license__ = 'BSD 3-Clause'
__version__ = "0.0.1"
__maintainer__ = 'Danilo Ramos'
__email__ = 'danilo.ramos@eideticom.com'

# __status__ = ["Prototype"|"Development"|"Production"]
__status__ = "Prototype"

import sys, os
import logging
import inspect

from pathlib import Path

from cocotb import start_soon
from cocotb.triggers import Timer, First
from cocotb.result import SimTimeoutError

# -----------------------------------------------------------------------------
async def with_timeout_msg(msg, trigger, timeout_time=1, timeout_unit="us"):
  # From [cocotb.triggers.with_timeout](https://docs.cocotb.org/en/stable/_modules/cocotb/triggers.html#with_timeout)
  log = logging.getLogger("cocotb.tb")
  if inspect.iscoroutine(trigger):
    trigger = start_soon(trigger)
    shielded = False
  else:
    shielded = True
  
  timeout_timer = Timer(timeout_time, timeout_unit)
  res = await First(timeout_timer, trigger)
  if res is timeout_timer:
    if not shielded:
      trigger.kill()
    log.error(f"TIMEOUT: {msg}")
    raise SimTimeoutError
  
  else:
    return res
  
# -----------------------------------------------------------------------------
def set_env_args(
  tb_class,
  timeout=10,
  load_env=False,
  **uut_params
):
  args = { nm:str(vl) for nm,vl in uut_params.items() }
  if load_env:
    args = load_env_args(args=args)
  return args

# -----------------------------------------------------------------------------
def load_env_args(args=None):
  if args is None:
    args = set_env_args()
    
    logging.debug(f"PARAMS_PRELOAD: {args}")
    for arg_nm, arg_dflt in args.items():
        args[arg_nm] = os.getenv(arg_nm, arg_dflt)
    
    # Options
    #args['nm'] = args['nm'].lower().replace(' ', '').split(',')
    #args['nm']  = None if args['nm']=='None' else int(args['nm'])
    #if isinstance(args['nm_enum'], str):
    #  args['nm_enum'] = EnumCast[args['nm_enum']]
    #args['nm_ast_lit'] = ast.literal_eval(args['nm_ast_lit'])
    #args['nm_bool'] = True if args['nm_bool']=='True' else False
    #args['dst_force_4k'] = True if args['dst_force_4k']=='True' else False
    
    args['timeout']      = None if args['timeout']=='None' else int(args['timeout'])
    
    logging.debug(f"PARAMS_LOAD: {args}")
    return args
