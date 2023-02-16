# ============================================================================
#  CoCoTB Makefile Template
#  Copyright (c) 2023. Danilo Ramos
#  All rights reserved.
#  This license message must appear in all versions of this code including
#  modified versions.
#  Licensed under MIT license.
# ============================================================================
# make {SIM=verilator|icarus} {WAVES=1} {COVERAGE=1}
# options:
#  RANDOM_SEED=1234
#  COCOTB_LOG_LEVEL=[DEBUG|INFO|WARNING|ERROR|CRITICAL]
#  TESTCASE=name_of_test_case_aka_function_to_run (decorated with cocotb.test)
#  COCOTB_RESOLVE_X=[VALUE_ERROR, ZEROS, ONES, RANDOM]
#    -> set to RANDOM (instead of CoCoTB default VALUE_ERROR)
#  PLUSARGS=+args (Verilog/SV)
# ============================================================================
TOPLEVEL_LANG ?= verilog
TOPLEVEL = qeng_revb_armif_test_h2f_lw_mux
MODULE ?= h2f_lw_mux_tb
SIM ?= verilator
WAVES ?= 0

# -----------------------------------------------------------------------
# Common sim parameters
COCOTB_HDL_TIMEUNIT = 1ns
COCOTB_HDL_TIMEPRECISION = 100ps
$(info simulation time(unit/precision): $(COCOTB_HDL_TIMEUNIT)/$(COCOTB_HDL_TIMEPRECISION) )
export COCOTB_RESOLVE_X ?= RANDOM
$(info RESOLVE_X set to $(COCOTB_RESOLVE_X))

# Disable short formating for debug
export COCOTB_REDUCED_LOG_FMT ?= 0
#export COCOTB_SCHEDULER_DEBUG ?= 1

# -----------------------------------------------------------------------
FILES := $(shell cat rtlfiles.lst)
VERILOG_SOURCES := $(FILES)
$(info Verilog files: )
$(info $(VERILOG_SOURCES) )

# -----------------------------------------------------------------------
# top-lvl parameters
export HW_PARAM_PARAM_NAME ?= 0

# -----------------------------------------------------------------------
# --------------------------------------
# - Verilator -
ifeq ($(SIM), verilator)
    $(info ------------------)
    $(info CoCoTB + Verilator)
    COMPILE_ARGS += -I../../../rtl
    # Supress common anoying verilator warnings (unnecessary here for sim, not linting)
    EXTRA_ARGS += -Wno-fatal -Wno-UNOPT -Wno-UNOPTFLAT -Wno-UNUSED -Wno-WIDTH
    EXTRA_ARGS += --assert
    # --------------------------------------
    # top-lvl parameters
    EXTRA_ARGS += -GPARAM_NAME=$(HW_PARAM_PARAM_NAME)
    
    # --------------------------------------
    # wave | coverage
    ifeq ($(WAVES), 1)
        $(info + wave (fst))
        EXTRA_ARGS += --trace-fst --trace-structs
    endif
    ifeq ($(COVERAGE), 1)
        $(info + coverage)
        EXTRA_ARGS += --coverage
    endif
    $(info ------------------)
endif

# --------------------------------------
# - Questa
ifeq ($(SIM), questa)
    $(info ------------------)
    $(info CoCoTB + Questa)
    COMPILE_ARGS += +incdir+../../../rtl
    # --------------------------------------
    # top-lvl parameters
    SIM_ARGS += -GGPARAM_NAME=$(HW_PARAM_PARAM_NAME)
    
    $(info ------------------)
endif

# --------------------------------------
# - Icarus -
ifeq ($(SIM), icarus)
    $(info ------------------)
    $(info CoCoTB + Icarus)
    # --------------------------------------
    COMPILE_ARGS += -I../../../rtl
    # top-lvl parameters
    COMPILE_ARGS += -P $(TOPLEVEL).PARAM_NAME=$(HW_PARAM_PARAM_NAME)
    # --------------------------------------
    # wave
    ifeq ($(WAVES), 1)
        $(info + wave (fst))
        PLUSARGS += -fst
        ICARUS_WAVE = icarus_wave.v
        VERILOG_SOURCES += $(ICARUS_WAVE)
        COMPILE_ARGS += -s icarus_wave
        # --------------------------------------
        # generate Icarus wave module
        # from CoCoTB
        $(file >  $(ICARUS_WAVE), module icarus_wave();)
        $(file >> $(ICARUS_WAVE), initial begin)
        $(file >> $(ICARUS_WAVE),     $$dumpfile("dump.fst");)
        $(file >> $(ICARUS_WAVE),     $$dumpvars(0, $(TOPLEVEL));)
        $(file >> $(ICARUS_WAVE),     #1;)
        $(file >> $(ICARUS_WAVE), end)
        $(file >> $(ICARUS_WAVE), endmodule)
    endif
    $(info ------------------)
endif

# --------------------------------------------------------------
$(info Starting CoCoTB... )
include $(shell cocotb-config --makefiles)/Makefile.sim

# -----------------------------------------------------------------------
# --------------------------------------------------------------
# Icarus (waveforms):
# from CoCoTB
icarus_wave.v:
	echo 'module icarus_wave();' > $@
	echo 'initial begin' >> $@
	echo '  $$dumpfile("$(TOPLEVEL).lxt2");' >> $@
	echo '  $$dumpvars(0, $(TOPLEVEL));' >> $@
	echo '  #1;' >> $@
	echo 'end' >> $@
	echo 'endmodule' >> $@

clean::
	rm -fr __pycache__ sim_build
	rm -rf iverilog_dump.v
	rm -rf dump.fst $(TOPLEVEL).fst
	rm -fr coverage.dat
