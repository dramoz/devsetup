#!/bin/bash
# --------------------------------------------------------------------------------
# Tools versions
xlnx_tools_pkg="Xilinx_Unified_2022.2_1014_8888"
xlnx_tools_ver="2022.2"
# --------------------------------------------------------------------------------
echo "---------------------------------------------------------"
echo "-> Please make sure that ./ubuntu_setup.sh was run before!!"
echo "--------------------------------------------------"
read -p "Install AMD/Xilinx Vitis/Vivado ver:${xlnx_tools_pkg} (y/n)? " ok
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
echo "Installing AMD/Xilinx Vitis/Vivado (https://docs.xilinx.com/r/en-US/ug1393-vitis-application-acceleration/Installing-Xilinx-Runtime-and-Platforms)"
mkdir -p ${HOME}/logs/xilinx
mkdir -p ${HOME}/dev/xilinx/vitis/${xlnx_tools_ver}
mkdir -p ${HOME}/dev/xilinx/vivado/${xlnx_tools_ver}
# Petalinux?
#sudo -S dpkg --add-architecture i386
#echo "Need to set bash as default shell (for petalinux)"
#echo "-> press [No] to switch to bash (as required)"
#sudo -S dpkg-reconfigure dash

cd ${HOME}/tmp
if [ ! -d ${xlnx_tools_pkg} ] && [ ! -f "${xlnx_tools_pkg}.tar.gz" ]; then
  echo "Download: Xilinx Unified Installer xxxx.x SFD (TAR/GZIP ~90 GB) (${xlnx_tools_pkg})"
  echo "!!! save to ~/tmp/"
  eval $browser "https://www.xilinx.com/member/forms/download/xef.html?filename=${xlnx_tools_pkg}.tar.gz" >/dev/null 2>&1
  read -p "Press [ENTER] key after download completed..." ok
fi

if [ ! -d "${xlnx_tools_pkg}" ] && [ -f "${xlnx_tools_pkg}.tar.gz" ]; then
  tar -xvzf ${xlnx_tools_pkg}.tar.gz
else
  echo "~/tmp/${xlnx_tools_pkg}.tar.gz file NOT found! (checking directory)"
fi

if [ -d ${xlnx_tools_pkg} ]; then
  echo "--------------------------------------------------"
  echo "!!! Install directory: ${TOOLS_PATH}/"
  echo "->Important (From AMD/Xilinx UG1393):"
  echo "*Do not deselect the following option. It is required for installation."
  echo "  [x] Devices > Install devices for Alveo and Xilinx Edge acceleration platforms"
  echo "  (https://docs.xilinx.com/r/en-US/ug1393-vitis-application-acceleration/Installing-the-Vitis-Software-Platform)"
  echo "--------------------------------------------------"
  echo "- Common options:"
  echo "  [] Uncheck Vitis Model Composer (MATLAB+Simulink required)"
  echo "  [] Uncheck unrequired FPGAs"
  echo "  BUT select: [x] Install devices for Alveo and Xilinx Edge acceleration platforms"

  cd ${xlnx_tools_pkg}
  ./xsetup
  read -p "Press [ENTER] key after installation is done..." ok
  sudo -S ${TOOLS_PATH}/Xilinx/Vitis/${xlnx_tools_ver}/scripts/installLibs.sh
  
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
  
  if ! grep -q "xilinx" "${HOME}/.bashrc_local"; then
    echo '# --------------------------------' >> ~/.bashrc_local
    echo '# xilinx' >> ~/.bashrc_local
    echo "export XILINX_DIR=\"\${TOOLS_PATH}/Xilinx\"" >> ~/.bashrc_local
    echo "export XILINX_VER=\"${xlnx_tools_ver}\"" >> ~/.bashrc_local
    echo '#export XILINXD_LICENSE_FILE=${HOME}/tools/xilinx/license.dat' >> ~/.bashrc_local
  fi
  
  # Launch tools setup
  cd ${HOME}/tools
  vitis_sh="vitis.${xlnx_tools_ver}.sh"
  if [ ! -f ${vitis_sh} ]; then
    touch ${vitis_sh}
    echo '#!/bin/bash' >> ${vitis_sh}
    echo '#set up XILINX_VITIS and XILINX_VIVADO variables' >> ${vitis_sh}
    echo "source ${TOOLS_PATH}/Xilinx/Vitis/${xlnx_tools_ver}/settings64.sh" >> ${vitis_sh}
    echo '#set up XILINX_XRT for data center platforms (not required for embedded platforms)' >> ${vitis_sh}
    echo 'source /opt/xilinx/xrt/setup.sh' >> ${vitis_sh}
    echo 'vitis &' >> ${vitis_sh}
    chmod +x ${vitis_sh}
  fi
  
  vivado_sh="vivado.${xlnx_tools_ver}.sh"
  if [ ! -f ${vivado_sh} ]; then
    touch ${vivado_sh}
    echo '#!/bin/bash' >> ${vivado_sh}
    echo "source ${TOOLS_PATH}/Xilinx/Vivado/${xlnx_tools_ver}/settings64.sh" >> ${vivado_sh}
    echo 'vivado -journal  logs/xilinx/vivado.jou -log logs/xilinx/vivado.log &' >> ${vivado_sh}
    chmod +x ${vivado_sh}
  fi
  
  echo "--------------------------------------------------"
  echo "Invoke tools from terminal with:"
  echo "$ vitis"
  echo "$ vivado"
  echo "--------------------------------------------------"
  echo "or from desktop (right click, Allow Launching)"
  echo "--------------------------------------------------"

else
  echo "~/tmp/${xlnx_tools_pkg} directory NOT found! Unable to proceed..."
fi

echo "--------------------------------------------------"
read -p "Done for the moment, reboot (y/n)? " ok
if [ "${ok}" == "y" ]; then
  echo "Sanity reboot..."
  sudo reboot
fi
