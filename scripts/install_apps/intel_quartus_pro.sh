#!/bin/bash
# --------------------------------------------------------------------------------
# Tools versions

# Quartus Pro 22.3
#intel_quartus_ver="22.3"
#intel_quartus_pkg="Quartus-pro-${intel_quartus_ver}.0.104-linux-complete"
#intel_quartus_url="https://cdrdv2.intel.com/v1/dl/getContent/746666/746690?filename=${intel_quartus_pkg}.tar"

# Quartus Pro 22.4
intel_quartus_ver="22.4"
intel_quartus_pkg="Quartus-pro-22.4.0.94-linux-complete"
intel_quartus_url="https://downloads.intel.com/akdlm/software/acdsinst/22.4/94/ib_tar/${intel_quartus_pkg}.tar"
# Embedded Tools
#deprecated -> intel_soceds_url="https://downloads.intel.com/akdlm/software/acdsinst/20.1/177/ib_installers/SoCEDSProSetup-20.1.0.177-linux.run"
intel_arm_ds_pkg="DS000-BN-00001-r22p2-00rel0"
intel_arm_ds_url="https://downloads.intel.com/akdlm/software/armds/2022.2/linux/DS000-BN-00001-r22p2-00rel0.tgz"

# --------------------------------------------------------------------------------
echo "---------------------------------------------------------"
echo "-> Please make sure that ./ubuntu_setup.sh was run before!!"
echo "--------------------------------------------------"
read -p "Install Intel SoC/FPGA tools (Quartus/Questa/ARM-DS):${intel_quartus_pkg} (y/n)? " ok
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

read -p "Install Intel Quartus Pro (${intel_quartus_ver})? (y/n)? " ok
if [ "${ok}" == "y" ]; then
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
    echo "  [x] Select Questa Pro"
    echo "--------------------------------------------------"
    echo "Get (free) license from: https://licensing.intel.com/psg/s/licenses-menu"
    echo "NIC: "
    ifconfig
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
      echo '#export LM_LICENSE_FILE=${HOME}/tools/intel/license.dat' >> ~/.bashrc_local
    fi
    
    if ! grep -q "questa" "${HOME}/.bashrc_local"; then
      echo '# --------------------------------' >> ~/.bashrc_local
      echo '# questa' >> ~/.bashrc_local
      echo "export QUESTA_ROOTDIR=\"\${TOOLS_PATH}/intelFPGA_pro/${intel_quartus_ver}/questa_fe\"" >> ~/.bashrc_local
      echo 'export PATH=$QUESTA_ROOTDIR/bin:$PATH' >> ~/.bashrc_local
      echo '#export LM_LICENSE_FILE=${HOME}/tools/intel/license.dat' >> ~/.bashrc_local
    fi
    
    echo "--------------------------------------------------"
    echo "Invoke tools from terminal with:"
    echo "$ quartus"
    echo "$ questa"
    echo "--------------------------------------------------"
    echo "or from desktop (right click, Allow Launching)"
    echo "--------------------------------------------------"
    
  else
    echo "~/tmp/${intel_quartus_pkg} directory NOT found! Unable to proceed..."
  fi
fi

read -p "Install Intel ARM-DS? (y/n)? " ok
if [ "${ok}" == "y" ]; then
  echo "----------------------------------------------------------------------------------------------------"
  echo "Installing ARM DS for Intel SoC FPGA Intel Quartus Pro (https://www.intel.com/content/www/us/en/software/programmable/soc-eds/arm-ds.html)"
  
  # Install dependencies
  #sudo -S apt install 
  
  #mkdir -p ${HOME}/logs/armds
  #mkdir -p ${HOME}/dev/intel/armds/${intel_quartus_ver}
  
  cd ${HOME}/tmp
  if [ ! -d ${intel_arm_ds_pkg} ] && [ ! -f "${intel_arm_ds_pkg}.tgz" ]; then
    echo "Download: Intel ARM DS(TGZ ~2GB) (${intel_arm_ds_pkg})"
    echo "!!! save to ~/tmp/"
    eval $browser "${intel_arm_ds_url}" >/dev/null 2>&1
    
    read -p "Press [ENTER] key after download completed..." ok
  fi

  if [ ! -d "${intel_arm_ds_pkg}" ] && [ -f "${intel_arm_ds_pkg}.tgz" ]; then
    tar xfv ${intel_arm_ds_pkg}.tgz
  else
    echo "~/tmp/${intel_arm_ds_pkg}.tgz file NOT found! (checking directory)"
  fi

  if [ -d ${intel_arm_ds_pkg} ]; then
    cd ${intel_arm_ds_pkg}
    echo "Installing..."
    echo "- Install path: ${TOOLS_PATH}/arm/developmentstudio-2022.2"
    ./armds-2022.2.sh
    
    if ! grep -q "armds" "${HOME}/.bashrc_local"; then
      echo '# --------------------------------' >> ~/.bashrc_local
      echo '# armds' >> ~/.bashrc_local
      echo "${TOOLS_PATH}/arm/developmentstudio-2022.2/bin/suite_exec" >> ~/.bashrc_local
    fi
    
  else
    echo "~/tmp/${intel_arm_ds_url} directory NOT found! Unable to proceed..."
  fi
fi

echo "--------------------------------------------------"
read -p "Done for the moment, reboot (y/n)? " ok
if [ "${ok}" == "y" ]; then
  echo "Sanity reboot..."
  sudo reboot
fi
