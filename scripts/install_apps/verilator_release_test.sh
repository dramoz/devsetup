
#!/bin/bash
# --------------------------------------------------------------------------------
# Setup env
unset VERILATOR_ROOT
cd ~/repos/verilator

# Install App
autoconf
./configure --prefix ${TOOLS_PATH}/verilator CFG_CXXFLAGS_STD_NEWEST="-std=gnu++20"
make -j$(nproc)
make install
