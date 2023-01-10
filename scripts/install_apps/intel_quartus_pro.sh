#!/bin/bash
# --------------------------------------------------------------------------------
# Tools versions
intel_quartus_ver="22.3"
intel_quartus_pkg="Quartus-pro-${intel_quartus_ver}.0.104-linux-complete"
intel_quartus_url="https://cdrdv2.intel.com/v1/dl/getContent/746666/746690?filename=${intel_quartus_pkg}.tar"
# --------------------------------------------------------------------------------
echo "---------------------------------------------------------"
echo "-> Please make sure that ./ubuntu_setup.sh was run before!!"
echo "--------------------------------------------------"
read -p "Install Intel Quartus Pro ver:${intel_quartus_pkg} (y/n)? " ok
if [ "${ok}" != "y" ]; then
  exit 1
fi

echo "----------------------------------------------------------------------------------------------------"
ubuntu_release=$(lsb_release -r)
ubuntu_ver=$(cut -f2 <<< "$ubuntu_release")
echo "$ubuntu_ver"
echo "Ubuntu: ${ubuntu_ver}"

if [[ $(grep -i Microsoft /proc/version) ]]; then
  WSL=1
  browser="/mnt/c/\"Program Files (x86)\"/Microsoft/Edge/Application/msedge.exe"
  echo "Under WSL..."
else
  WSL=0
  browser="firefox -new-window"
fi

echo "--------------------------------------------------"
# Ubuntu update
echo "update/upgrade/remove"
sudo -S apt update -y && sudo -S apt upgrade -y && sudo apt dist-upgrade -y && sudo apt autoremove -y

echo "--------------------------------------------------"
# R&D dirs
echo "Creating common dirs..."
cd ~; mkdir -p dev tools repos tmp

echo "----------------------------------------------------------------------------------------------------"
echo "Installing Intel Quartus Pro (https://www.intel.com/content/www/us/en/docs/programmable/683472/22-3/downloading-and-installing-fpga-software.html)"
sudo -S apt install libncurses5
mkdir -p ${HOME}/logs/quartus
mkdir -p ${HOME}/dev/intel/quartus/${intel_quartus_ver}

cd ${HOME}/tmp
if [ ! -d ${intel_quartus_pkg} ] && [ ! -f "${intel_quartus_pkg}.tar" ]; then
  echo "Download: Intel Quartus Pro (TAR ~90GB) (${intel_quartus_pkg})"
  echo "!!! save to ~/tmp/"
  eval $browser "${intel_quartus_url}" >/dev/null 2>&1
  
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
  echo "!!! Install directory: ${TOOLS_PATH}/intelFPGA_pro/${intel_quartus_ver}/"
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
    echo "export QUARTUS_ROOTDIR=\"\${TOOLS_PATH}/intelFPGA_pro/${intel_quartus_ver}/quartus\"" >> ~/.bashrc_local
    echo 'export QSYS_ROOTDIR=$QUARTUS_ROOTDIR/qsys/bin' >> ~/.bashrc_local
    echo 'export PATH=$QUARTUS_ROOTDIR/bin:$PATH' >> ~/.bashrc_local
    echo 'export LM_LICENSE_FILE=${HOME}/tools/intel/license.dat' >> ~/.bashrc_local
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
