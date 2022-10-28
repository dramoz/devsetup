#!/bin/bash
# --------------------------------------------------------------------------------
# Tools versions
risv_toolchain_ver="10.2.0-2020.12.8-x86_64-linux-ubuntu14"
xlnx_tools_inst_ver="Xilinx_Unified_2022.2_1014_8888"
xlnx_tools_ver="2022.2"
intel_quartus_inst_ver="Quartus-pro-22.3.0.104"
intel_quartus_ver="22.3"

# --------------------------------------------------------------------------------
echo "---------------------------------------------------------"
echo "Install R&D Tools"
echo "--------------------------------------------------"
echo "Tools:"
echo "- RISC-V toolchain (SiFive default), ver:${risv_toolchain_ver}"
echo "- AMD/Xilinx Vitis/Vivado, ver:${xlnx_tools_inst_ver}"
echo "- Intel Quartus Pro, ver:${intel_quartus_inst_ver}"
echo "--------------------------------------------------"
echo "-> Please make sure that ./ubuntu_setup.sh was run before!!"
read -p "Continue (y/n)? " ok

if [ "${ok}" == "n" ]; then
  exit 1
fi

# --------------------------------------------------------------------------------
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

echo "----------------------------------------------------------------------------------------------------"
auto=0
if [ ! -z "$1" ]; then
  if [ "$1" == "y" ]; then
    echo "Running the script in partial auto/all mode"
    echo "--------------------------------------------------"
    read -p "Proceed (y/n)? " ok
    if [ "${ok}" == "y" ]; then
      auto=1
    fi
    echo "----------------------------------------------------------------------------------------------------"
  fi
fi

# Ubuntu update
echo "--------------------------------------------------"
echo "update/upgrade/remove"
sudo -S apt update -y && sudo -S apt upgrade -y && sudo apt dist-upgrade -y && sudo apt autoremove -y

# R&D dirs
echo "--------------------------------------------------"
echo "Creating common dirs..."
cd ~; mkdir -p dev tools repos tmp

# RISC-V toolchain
echo "--------------------------------------------------"
if [ ${auto} -eq 1 ]; then
  ok="y"
else
  read -p "Install RISC-V toolchain (SiFive) (y/n)? " ok
fi

if [ "${ok}" == "y" ]; then
  # Install
  cd ${HOME}/tmp
  wget https://static.dev.sifive.com/dev-tools/freedom-tools/v2020.12/riscv64-unknown-elf-toolchain-${risv_toolchain_ver}.tar.gz
  tar -xvzf riscv64-unknown-elf-toolchain-${risv_toolchain_ver}.tar.gz
  rm -f riscv64-unknown-elf-toolchain-${risv_toolchain_ver}.tar.gz
  mv riscv64-unknown-elf-toolchain-${risv_toolchain_ver} ${HOME}/tools/riscv64-unknown-elf-toolchain
  if ! grep -q "riscv" "${HOME}/.bashrc_local"; then
    echo '# --------------------------------'  >> ~/.bashrc_local
    echo '# RISC-V Toolchain' >> ~/.bashrc_local
    echo 'export PATH=${HOME}/tools/riscv64-unknown-elf-toolchain/bin:$PATH' >> ~/.bashrc_local
  fi
fi

echo "--------------------------------------------------"
if [ ${auto} -eq 1 ]; then
  ok="y"
else
  read -p "Install AMD/Xilinx Vitis/Vivado (y/n)? " ok
fi
if [ "${ok}" == "y" ]; then
  echo "Installing AMD/Xilinx Vitis/Vivado (https://docs.xilinx.com/r/en-US/ug1393-vitis-application-acceleration/Installing-Xilinx-Runtime-and-Platforms)"
  mkdir -p ${HOME}/logs/xilinx
  
  # Petalinux?
  #sudo -S dpkg --add-architecture i386
  #echo "Need to set bash as default shell (for petalinux)"
  #echo "-> press [No] to switch to bash (as required)"
  #sudo -S dpkg-reconfigure dash
  
  cd ${HOME}/tmp
  if [ ! -d ${xlnx_tools_inst_ver} ] && [ ! -f "${xlnx_tools_inst_ver}.tar.gz" ]; then
    echo "Download: Xilinx Unified Installer xxxx.x SFD (TAR/GZIP ~100 GB) (${xlnx_tools_inst_ver})"
    echo "!!! save to ~/tmp/"
    eval $browser "https://www.xilinx.com/member/forms/download/xef.html?filename=${xlnx_tools_inst_ver}.tar.gz"
    read -p "Press [ENTER] key after download completed..." ok
  fi
  
  if [ ! -d "${xlnx_tools_inst_ver}" ] && [ -f "${xlnx_tools_inst_ver}.tar.gz" ]; then
    tar -xvzf ${xlnx_tools_inst_ver}.tar.gz
  else
    echo "~/tmp/${xlnx_tools_inst_ver}.tar.gz file NOT found! (checking directory)"
  fi
  
  if [ -d ${xlnx_tools_inst_ver} ]; then
    echo "--------------------------------------------------"
    echo "!!! Install directory: ${HOME}/tools/"
    echo "->Important (From AMD/Xilinx UG1393):"
    echo "*Do not deselect the following option. It is required for installation."
    echo "  [x] Devices > Install devices for Alveo and Xilinx Edge acceleration platforms"
    echo "  (https://docs.xilinx.com/r/en-US/ug1393-vitis-application-acceleration/Installing-the-Vitis-Software-Platform)"
    echo "--------------------------------------------------"
    echo "- Common options:"
    echo "  [] Uncheck Vitis Model Composer (MATLAB+Simulink required)"
    echo "  [] Uncheck unrequired FPGAs"
    echo "  BUT select: [x] Install devices for Alveo and Xilinx Edge acceleration platforms"

    cd ${xlnx_tools_inst_ver}
    ./xsetup
    read -p "Press [ENTER] key after installation is done..." ok
    sudo -S ${HOME}/tools/Xilinx/Vitis/${xlnx_tools_ver}/scripts/installLibs.sh
    
    # Xilinx Runtime (XRT)
    # -> This is required for the embedded OS, but not host!!!
    #cd ${HOME}/tmp
    #echo "Installing Xilinx Runtime (XRT) (https://xilinx.github.io/XRT/2022.2/html/index.html)"
    #if [ "`echo "${ubuntu_ver} == 22.04" | bc`" -eq 1 ]; then
    #  xlnx_xrt_ver="202220.2.14.354_22.04-amd64-xrt"
    #fi
    #if [ "`echo "${ubuntu_ver} == 20.04" | bc`" -eq 1 ]; then
    #  xlnx_xrt_ver="202220.2.14.354_20.04-amd64-xrt"
    #fi
    #wget -O "xrt_${xlnx_xrt_ver}.deb" "https://www.xilinx.com/bin/public/openDownload?filename=xrt_${xlnx_xrt_ver}.deb"
    #sudo -S apt install -y ./xrt_${xlnx_xrt_ver}.deb
    
    # Launch tools setup
    cd ${HOME}/tools
    vitis_sh="vitis_${xlnx_tools_ver}.sh"
    if [ ! -f ${vitis_sh} ]; then
      touch ${vitis_sh}
      echo '#!/bin/bash' >> ${vitis_sh}
      echo '#set up XILINX_VITIS and XILINX_VIVADO variables' >> ${vitis_sh}
      echo "source ~/tools/Xilinx/Vitis/${xlnx_tools_ver}/settings64.sh" >> ${vitis_sh}
      echo '#set up XILINX_XRT for data center platforms (not required for embedded platforms)' >> ${vitis_sh}
      echo 'source /opt/xilinx/xrt/setup.sh' >> ${vitis_sh}
      echo 'vitis &' >> ${vitis_sh}
      chmod +x ${vitis_sh}
    fi
    
    vivado_sh="vivado_${xlnx_tools_ver}.sh"
    if [ ! -f ${vivado_sh} ]; then
      touch ${vivado_sh}
      echo '#!/bin/bash' >> ${vivado_sh}
      echo "source ~/tools/Xilinx/Vivado/${xlnx_tools_ver}/settings64.sh" >> ${vivado_sh}
      echo 'vivado -journal logs/xilinx -log logs/xilinx &' >> ${vivado_sh}
      chmod +x ${vivado_sh}
    fi
    
  else
    echo "~/tmp/${xlnx_tools_inst_ver} directory NOT found! Unable to proceed..."
  fi
fi

echo "--------------------------------------------------"
if [ ${auto} -eq 1 ]; then
  ok="y"
else
  read -p "Install Intel Quartus Pro (y/n)? " ok
fi
if [ "${ok}" == "y" ]; then
  echo "Installing Intel Quartus Pro"
  cd ${HOME}/tmp
  rm -fr ${intel_quartus_inst_ver}-linux-complete
  mkdir ${intel_quartus_inst_ver}-linux-complete
  cd ${intel_quartus_inst_ver}-linux-complete
  
  #echo "Attemping to automatically download Intel Quartus Pro ${intel_quartus_inst_ver}-linux-complete.tar"
  #wget "https://cdrdv2.intel.com/v1/dl/getContent/746666/746690?filename=${intel_quartus_inst_ver}-linux-complete.tar"
  echo "Download: Intel Quartus Pro (${intel_quartus_inst_ver}-linux-complete.tar) (TAR - 85.5 GB)"
  echo "!!! save to ~/tmp/"
  cd ${HOME}/tmp
  eval $browser "https://www.intel.ca/content/www/ca/en/software-kit/current/657472.html"
  read -p "Press [ENTER] key after download completed..." ok
  
  if [ -f "${intel_quartus_inst_ver}-linux-complete.tar" ]; then
    tar -xvf ${intel_quartus_inst_ver}-linux-complete.tar
    
    read -p "Press [ENTER] key after installation is done..." ok
    
  else
    echo "~/tmp/${intel_quartus_inst_ver}-linux-complete.tar file NOT found!"
  fi
fi

echo "--------------------------------------------------"
if [ ${auto} -eq 1 ]; then
  ok="y"
else
  read -p "Done for the moment, reboot (y/n)? " ok
fi
if [ "${ok}" == "y" ]; then
  echo "Sanity reboot..."
  sudo reboot
fi
