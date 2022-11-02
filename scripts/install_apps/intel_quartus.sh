#!/bin/bash
# --------------------------------------------------------------------------------
# Tools versions
intel_quartus_pkg="Quartus-pro-22.3.0.104-linux-complete"
intel_quartus_ver="22.3"
# --------------------------------------------------------------------------------
echo "---------------------------------------------------------"
echo "-> Please make sure that ./ubuntu_setup.sh was run before!!"
echo "--------------------------------------------------"
read -p "Install Intel Quartus Pro ver:${intel_quartus_pkg} (y/n)? " ok
if [ "${ok}" != "y" ]; then
  exit 1
fi

echo "Installing Intel Quartus Pro (https://www.intel.com/content/www/us/en/docs/programmable/683472/22-3/downloading-and-installing-fpga-software.html)"
sudo -S apt install libncurses5
mkdir -p ${HOME}/logs/quartus
mkdir -p ${HOME}/dev/intel/quartus/${intel_quartus_ver}

cd ${HOME}/tmp
if [ ! -d ${intel_quartus_pkg} ] && [ ! -f "${intel_quartus_pkg}.tar" ]; then
  echo "Download: Intel Quartus Pro (TAR ~90GB) (${intel_quartus_pkg})"
  echo "!!! save to ~/tmp/"
  #eval $browser "https://www.intel.ca/content/www/ca/en/software-kit/current/657472.html" >/dev/null 2>&1
  eval $browser "https://cdrdv2.intel.com/v1/dl/getContent/746666/746690?filename=${intel_quartus_pkg}.tar" >/dev/null 2>&1
  
  read -p "Press [ENTER] key after download completed..." ok
fi

if [ ! -d "${intel_quartus_pkg}" ] && [ -f "${intel_quartus_pkg}.tar" ]; then
  mkdir ${intel_quartus_pkg}
  cd ${intel_quartus_pkg}
  tar -xvf ../${intel_quartus_pkg}.tar
  cd ..
else
  echo "~/tmp/${intel_quartus_pkg}.tar file NOT found! (checking directory)"
fi

if [ -d ${intel_quartus_pkg} ]; then
  echo "--------------------------------------------------"
  echo "!!! Install directory: ${HOME}/tools/intel/intelFPGA_pro/${intel_quartus_ver}/"
  echo "--------------------------------------------------"
  echo "- Common options:"
  echo "  [] Uncheck DSP Builder (MATLAB+Simulink required)"
  echo "  [] Uncheck SDK for OpenCL"
  echo "  [] Uncheck unrequired FPGAs"
  echo "--------------------------------------------------"
  echo "Get (free) license from: https://licensing.intel.com/psg/s/licenses-menu"
  echo "NIC: "
  ifconfig /all
  echo "--------------------------------------------------"
  
  cd ${intel_quartus_pkg}
  #${intel_quartus_pkg}.run --mode unattended --unattendedmodeui minimal --installdir ${HOME}/dev/tools/intel --accept_eula 1
  ./setup_pro.sh
  
  if ! grep -q "quartus" "${HOME}/.bashrc_local"; then
    echo '# --------------------------------' >> ~/.bashrc_local
    echo '# quartus' >> ~/.bashrc_local
    echo "export QUARTUS_ROOTDIR=\"${HOME}/tools/intel/intelFPGA_pro/${intel_questa_ver}/quartus\"" >> ~/.bashrc_local
    echo 'export QSYS_ROOTDIR="$QUARTUS_ROOTDIR/qsys/bin' >> ~/.bashrc_local
    echo 'export PATH="$QUARTUS_ROOTDIR/bin:$PATH' >> ~/.bashrc_local
    echo 'export LM_LICENSE_FILE="${HOME}/tools/intel/intelFPGA_pro/${intel_questa_ver}/license.dat' >> ~/.bashrc_local
  fi
  
  echo "--------------------------------------------------"
  echo "Invoke tools from terminal with:"
  echo "$ quartus"
  echo "--------------------------------------------------"
  echo "or from desktop (right click, Allow Launching)"
  echo "--------------------------------------------------"
  
else
  echo "~/tmp/${intel_quartus_pkg} directory NOT found! Unable to proceed..."
fi

echo "--------------------------------------------------"
read -p "Done for the moment, reboot (y/n)? " ok
if [ "${ok}" == "y" ]; then
  echo "Sanity reboot..."
  sudo reboot
fi