#!/bin/bash
source /usr/local/bin/virtualenvwrapper.sh
workon xilinx
source ~/tools/Xilinx/Vivado/2021.2/settings64.sh
vivado &
