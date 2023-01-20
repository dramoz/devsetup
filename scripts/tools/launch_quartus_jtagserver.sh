#!/bin/bash
# --------------------------------------------------------------------------------
## Check that jtagd is running:
# ps -ef | grep jtagd

## Check jtagd port is open
# netstat -na | grep :1309

## Check jtagd connection status
# netstat -lntu | grep 1309

# --------------------------------------------------------------------------------
# References
#  https://www.intel.com/content/www/us/en/docs/programmable/683472/21-4/installing-and-configuring-a-local-jtag.html
#  https://edg.uchicago.edu/tutorials/enable_remote_jtagd/
# --------------------------------------------------------------------------------
if [ -d ${QUARTUS_ROOTDIR} ]; then
  if [! -d /etc/jtagd ]; then
    sudo -S mkdir /etc/jtagd
    sudo -S chmod 777 /etc/jtagd 
  fi
  
  cd ${QUARTUS_ROOTDIR}/bin
  ./jtagd
  ./jtagconfig --enableremote jtAg1234
  
else
  echo "Unable to start jtagd daemon, QUARTUS_ROOTDIR not found"
  
fi