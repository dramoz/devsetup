#!/bin/bash
cd ${QUARTUS_ROOTDIR}/linux64
export LD_LIBRARY_PATH=$(pwd)
./jtagd
./jtagconfig --enableremote 123456
