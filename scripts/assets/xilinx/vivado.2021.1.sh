#!/bin/bash
source /home/dramoz/.local/bin/virtualenvwrapper.sh
workon xilinx
source ~/tools/Xilinx/Vivado/2021.1/settings64.sh
vivado -journal logs/xilinx -log logs/xilinx &
