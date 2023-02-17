# ----------------------------------------------------------------------
# Single test script run (use *dbg.py)
make clean; script -c "WAVES=1 LOGLEVEL=INFO MODULE=test_tcname RANDOM_SEED=1234 SIM=verilator make"

# Debug level on all (MODELS_LOGLEVEL=)
make clean; script -c "WAVES=1 LOGLEVEL=DEBUG MODELS_LOGLEVEL=DEBUG MODULE=test_tcname RANDOM_SEED=1234 SIM=verilator make"

# Sanity with pytest (verbose, one by one)
make clean; script -c "WAVES=1 LOGLEVEL=INFO pytest test_name.py -c ./singleton.ini"

#Pytest run multithread
make clean; script -c "WAVES=1 LOGLEVEL=INFO pytest"

# List/Run sanity TCs
make clean; script -c "WAVES=1 LOGLEVEL=INFO pytest -k expression --collect-only"

# factory test, not recommended/only for debug - run pytest
make clean; script -c "LOGLEVEL=INFO MODULE=test_tcname RANDOM_SEED=1234 AS_FACTORY=1 SIM=verilator make"
