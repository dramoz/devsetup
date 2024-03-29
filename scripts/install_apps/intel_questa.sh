#!/bin/bash
# --------------------------------------------------------------------------------
# Tools versions
intel_questa_setup="QuestaSetup-22.3.0.104-linux.run"
intel_questa_pkg="questa_part2-22.3.0.104-linux.qdz"
intel_questa_ver="22.3"
# --------------------------------------------------------------------------------
echo "---------------------------------------------------------"
echo "-> Please make sure that ./ubuntu_setup.sh was run before!!"
echo "--------------------------------------------------"
read -p "Install Intel Questa ver:${intel_questa_setup} (y/n)? " ok
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
echo "Installing Questa (https://www.intel.com/content/www/us/en/docs/programmable/683472/22-3/downloading-and-installing-fpga-software.html)"
sudo -S apt install libncurses5
mkdir -p ${HOME}/logs/questa
mkdir -p ${HOME}/dev/intel/questa/${intel_questa_ver}

cd ${HOME}/tmp
if [ ! -f "${intel_questa_setup}" ]; then
  echo "Download: Intel Quartus/Questa Setup (BIN ~1GB) (${intel_questa_setup})"
  echo "!!! save to ~/tmp/"
  eval $browser "https://cdrdv2.intel.com/v1/dl/downloadStart/746695/746699?filename=${intel_questa_setup}" >/dev/null 2>&1
  read -p "Press [ENTER] key after download completed..." ok
fi

if [ ! -f "${intel_questa_pkg}" ]; then
  echo "Download: Intel Questa PKG (~23GB) (${intel_questa_setup})"
  echo "!!! save to ~/tmp/"
  eval $browser "https://downloads.intel.com/akdlm/software/acdsinst/22.3/104/ib_installers/${intel_questa_pkg}" >/dev/null 2>&1
  read -p "Press [ENTER] key after download completed..." ok
fi

if [ -f "${intel_questa_setup}" ] && [ -f "${intel_questa_pkg}" ]; then
  echo "--------------------------------------------------"
  echo "!!! Install directory: ${TOOLS_PATH}/intelFPGA_pro/${intel_questa_ver}/"
  echo "--------------------------------------------------"
  echo "Get (free) license from: https://licensing.intel.com/psg/s/licenses-menu"
  echo "NIC: "
  ifconfig -a
  echo "--------------------------------------------------"
  
  if ! grep -q "questa" "${HOME}/.bashrc_local"; then
    echo '# --------------------------------' >> ~/.bashrc_local
    echo '# questa' >> ~/.bashrc_local
    echo "export QUESTA_ROOTDIR=\"\${TOOLS_PATH}/intelFPGA_pro/${intel_questa_ver}/questa_fe\"" >> ~/.bashrc_local
    echo 'export PATH=$QUESTA_ROOTDIR/bin:$PATH' >> ~/.bashrc_local
    echo 'export LM_LICENSE_FILE=${HOME}/tools/intel/license.dat' >> ~/.bashrc_local
  fi
  
  chmod +x ${intel_questa_setup}
  ./${intel_questa_setup}
  
  echo "--------------------------------------------------"
  echo "Invoke tools from terminal with:"
  echo "$ vsim"
  echo "--------------------------------------------------"
  
else
  if [ ! -f "${intel_questa_setup}" ]; then
    echo "~/tmp/${intel_questa_setup} file NOT found!"
  fi
  if [ ! -f "${intel_questa_pkg}" ]; then
    echo "~/tmp/${intel_questa_pkg} file NOT found!"
  fi
fi

echo "--------------------------------------------------"
read -p "Done for the moment, reboot (y/n)? " ok
if [ "${ok}" == "y" ]; then
  echo "Sanity reboot..."
  sudo reboot
fi
