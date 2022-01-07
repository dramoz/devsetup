#!/bin/bash
source /usr/local/bin/virtualenvwrapper.sh
workon xilinx
source ~/tools/Xilinx/Vivado/2021.1/settings64.sh
vivado -journal xilinx/logs -log logs/xilinx &
