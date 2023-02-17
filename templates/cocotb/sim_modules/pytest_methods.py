#####################################################################################
#  Copyright (c) 2023 Eidetic Communications Inc.
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


import ast, os, sys, os
import inspect
import logging
import math
import pytest
import re

from itertools import product
from pathlib import Path
from slugify import slugify

from cocotb.regression import TestFactory, _create_test

# -----------------------------------------------------------------------------
# Internal modules
_workpath = Path(__file__).resolve().parent
sys.path.append(str(_workpath))
sys.path.append(str(_workpath.parent))


from sim_modules.run_cocotb_sim import run_cocotb_sim
from cocotb_methods import set_env_args

# -----------------------------------------------------------------------------
class TestFactoryWithNames(TestFactory):
    def generate_tests(self, prefix="", postfix="", postfix_testoptions='+'):
        """
        Generate an exhaustive set of tests using the cartesian product of the
        possible keyword arguments.

        The generated tests are appended to the namespace of the calling
        module.

        Args:
            prefix (str):  Text string to append to start of ``test_function`` name
                     when naming generated test cases. This allows reuse of
                     a single ``test_function`` with multiple
                     :class:`TestFactories <.TestFactory>` without name clashes.
            postfix (str): Text string to append to end of ``test_function`` name
                     when naming generated test cases. This allows reuse of
                     a single ``test_function`` with multiple
                     :class:`TestFactories <.TestFactory>` without name clashes.
            postfix_testoptions (str): If set, postfix name with optname=optvalue
        """

        frm = inspect.stack()[1]
        mod = inspect.getmodule(frm[0])

        d = self.kwargs

        for index, testoptions in enumerate(
                dict(zip(d, v)) for v in
                product(*d.values())
        ):

            doc = "Automatically generated test\n\n"

            # preprocess testoptions to split tuples
            testoptions_split = {}
            for optname, optvalue in testoptions.items():
                if isinstance(optname, str):
                    testoptions_split[optname] = optvalue
                else:
                    # previously checked in add_option; ensure nothing has changed
                    assert len(optname) == len(optvalue)
                    for n, v in zip(optname, optvalue):
                        testoptions_split[n] = v

            for optname, optvalue in testoptions_split.items():
                if callable(optvalue):
                    if not optvalue.__doc__:
                        desc = "No docstring supplied"
                    else:
                        desc = optvalue.__doc__.split('\n')[0]
                    doc += "\t{}: {} ({})\n".format(optname, optvalue.__qualname__, desc)
                else:
                    doc += "\t{}: {}\n".format(optname, repr(optvalue))
            
            if postfix_testoptions:
                name = "%s%s%s%s" % (prefix, self.name, postfix, postfix_testoptions)
                name += f"{postfix_testoptions.join([f'{optname}={str(optvalue)}' for optname, optvalue in testoptions_split.items()])}"
            else:
                name = "%s%s%s_%03d" % (prefix, self.name, postfix, index + 1)
            
            self.log.debug("Adding generated test \"%s\" to module \"%s\"" %
                           (name, mod.__name__))
            kwargs = {}
            kwargs.update(self.kwargs_constant)
            kwargs.update(testoptions_split)
            if hasattr(mod, name):
                self.log.error("Overwriting %s in module %s. "
                               "This causes a previously defined testcase "
                               "not to be run. Consider setting/changing "
                               "name_postfix" % (name, mod))
            setattr(mod, name, _create_test(self.test_function, name, doc, mod,
                                            *self.args, **kwargs))

# -----------------------------------------------------------------------------
# Utils
# -----------------------------------------------------------------------------
def ids(arg_name):
    return lambda x, vl_only=False: f'{x}' if vl_only==True else (f'{arg_name}' + (f'[{x}]' if x is not None else f'[-]'))
    
def ids_enum(arg_name):
    return lambda x, vl_only=False: f'{x.name}' if vl_only==True else (f'{arg_name}' + (f'[{x.name}]' if x is not None else f'[-]'))
    
def no_pytest(arg_name, arg_values, ids_op):
    #re.sub("[]", '', ids_op(x, True))
    return lambda x: f'{arg_name}' #+ f'[{[ ids_op(x, True) for x in arg_values ]}]'

def conditional_parametrize(from_pytest, argname, argvalues, ids):
    def decorator(func):
        if from_pytest not in ['all', ['all']] and argname not in from_pytest:
            return pytest.mark.parametrize(argnames=f"{argname}", argvalues=[None], ids=no_pytest(argname, argvalues, ids))(func)
        return pytest.mark.parametrize(argnames=argname, argvalues=argvalues, ids=ids)(func)
    return decorator

# -----------------------------------------------------------------------------
def pytest_purge_tests(tests, from_pytest, requested=None):
    pytest_run = os.getenv('PYTEST_CURRENT_TEST', None)
    #logging.critical(f":{pytest_run}")
    if requested is not None:
        # Need a string literal for ast
        requested = str(requested)
    requested = os.getenv('REQUESTED_TESTS', requested)
    #logging.critical(f":{requested}")
    total_tests = sum( [ math.prod([len(param) if isinstance(param, list) else 1 for param in test['args']]) for test in tests.values() ])
    if requested is not None:
        requested = ast.literal_eval(requested)
        if requested in ["None", 'all']:
            pass
        else:
            tests = {nm:args for nm,args in tests.items() if nm in requested}
    
    assert tests, f'Test list is empty!'
    
    if pytest_run is not None:
        # ARGs that are set in from_pytest, are loaded by pytest with mark.parametrize
        logging.critical(f"Running pytest:{pytest_run}")
        for test_data in tests.values():
            if from_pytest in ['all', ['all']]:
                continue
            
            elif from_pytest in ['none', 'None']:
                test_data['args'] = {}
            
            else:
                for pt in from_pytest:
                    if pt in test_data['args']:
                        del test_data['args'][pt]
                
    total_factory_tests = sum( [ math.prod([len(param) if isinstance(param, list) else 1 for param in test['args']]) for test in tests.values() ])
    logging.critical(f"TestFactory[{total_factory_tests}/{total_tests}]: {tests}")
    
    return tests #, total_tests, total_factory_tests
        
# -----------------------------------------------------------------------------
def set_and_run_sim(
    pymodule, workpath, tests, tb_class, uut_param_class,
    request,
    DATA_BYTES=None, MAX_PAYLOAD=None, MAX_READ_REQUEST=None,
    engines=None, pkts=None, pkts_burst=None, length=None, addressing=None, zero_len_eop=None, nvme_type=None, desc_type=None, head=None, gap_vl=0,
    mem_rd_rnd_completion_response=False,
    src_force_4k=False, dst_force_4k=False,
    as_pytest=1,
):
    set_args = locals()
    sim_params = { arg:set_args[arg] for arg in ['MAX_PAYLOAD', 'MAX_READ_REQUEST']}
    dut_params = { arg:set_args[arg] for arg in ['DATA_BYTES']}
    for narg in ['pymodule', 'workpath', 'tests', 'uut_param_class', 'request', 'as_pytest']+list(sim_params.keys())+list(dut_params.keys()):
        del set_args[narg]
    
    logging.critical(f"sim_set_args{set_args}")
    args = set_env_args(**set_args)
    args = {nm:vl for nm,vl in args.items() if nm in set_args and set_args[nm] is not None or nm not in set_args}
    
    test_id = slugify(request.node.name, separator='_')
    args.update({
        'TEST_ID': str(test_id),
        'REQUESTED_TESTS': str(tests),
        'AS_PYTEST': str(as_pytest)
    })
    args.update({arg:str(vl) for arg,vl in sim_params.items() if vl is not None})
    args.update({arg:str(vl) for arg,vl in dut_params.items() if vl is not None})
    
    logging.critical(f"Running pytest: {args}")
    
    dut = uut_param_class()
    for param_nm, param_vl in dut_params.items():
        if param_vl is not None:
            dut.parameters[param_nm] = param_vl
            
    sims = int(os.getenv("TOTAL_SIMS", 1))
    logging.critical(f"sim_args{args}")
    for _ in range(sims):
        run_cocotb_sim(
            module=pymodule,
            top_level=dut.toplevel,
            test_name=test_id,
            include_dirs=['../../../../../rtl/'],
            hdl_sources=dut.verilog_sources,
            parameters=dut.parameters,
            testcase=None,
            workpath=workpath,
            extra_env=args,
        )
        