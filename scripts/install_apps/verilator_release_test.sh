
#!/bin/bash
# --------------------------------------------------------------------------------
# Setup env
unset VERILATOR_ROOT
cd ~/repos/verilator

# Install App
autoconf
./configure --prefix ${HOME}/tools/verilator
make -j$(nproc)
make install
