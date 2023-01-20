#!/bin/bash
#https://www.intel.com/content/www/us/en/docs/programmable/683472/21-4/installing-and-configuring-a-local-jtag.html
cd ${QUARTUS_ROOTDIR}/linux64
export LD_LIBRARY_PATH=$(pwd)
./jtagd
./jtagconfig --enableremote jtAg1234
