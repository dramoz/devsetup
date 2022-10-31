#!/bin/bash
# --------------------------------------------------------------------------------
# Tools versions
risv_toolchain_ver="10.2.0-2020.12.8-x86_64-linux-ubuntu14"

xlnx_tools_pkg="Xilinx_Unified_2022.2_1014_8888"
xlnx_tools_ver="2022.2"

intel_quartus_pkg="Quartus-pro-22.3.0.104-linux-complete"
intel_quartus_ver="22.3"

verilator_tag="v4.228.1"
cocotb_bus_tag="v0.1.0"
cocotbext_pcie_tag="eid"
cocotbext_axi_tag="master"

# --------------------------------------------------------------------------------
echo "---------------------------------------------------------"
echo "Install R&D Tools"
echo "--------------------------------------------------"
echo "Tools:"
echo "- RISC-V toolchain (SiFive default), ver:${risv_toolchain_ver}"
echo "- AMD/Xilinx Vitis/Vivado, ver:${xlnx_tools_pkg}"
echo "- Intel Quartus Pro, ver:${intel_quartus_pkg}"
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
    echo '# riscv' >> ~/.bashrc_local
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

    cd ${xlnx_tools_pkg}
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
    vitis_sh="vitis.${xlnx_tools_ver}.sh"
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
    
    vivado_sh="vivado.${xlnx_tools_ver}.sh"
    if [ ! -f ${vivado_sh} ]; then
      touch ${vivado_sh}
      echo '#!/bin/bash' >> ${vivado_sh}
      echo "source ~/tools/Xilinx/Vivado/${xlnx_tools_ver}/settings64.sh" >> ${vivado_sh}
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
fi

echo "--------------------------------------------------"
if [ ${auto} -eq 1 ]; then
  ok="y"
else
  read -p "Install Intel Quartus Pro (y/n)? " ok
fi
if [ "${ok}" == "y" ]; then
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
    cd ${intel_quartus_pkg}
    #${intel_quartus_pkg}.run --mode unattended --unattendedmodeui minimal --installdir ${HOME}/dev/tools/intel --accept_eula 1
    ./setup_pro.sh
    
    if ! grep -q "quartus" "${HOME}/.bashrc_local"; then
      echo '# --------------------------------' >> ~/.bashrc_local
      echo '# quartus' >> ~/.bashrc_local
      echo "export QUARTUS_ROOTDIR=\"${HOME}/tools/intel/intelFPGA_pro/${intel_quartus_ver}/quartus\"" >> ~/.bashrc_local
      echo 'export QSYS_ROOTDIR="$QUARTUS_ROOTDIR/qsys/bin"' >> ~/.bashrc_local
      echo '#export PATH="$QUARTUS_ROOTDIR/bin:$QSYS_ROOTDIR:__^S^__PATH" ' >> ~/.bashrc_local
      echo 'export PATH="$QUARTUS_ROOTDIR/bin:$PATH" ' >> ~/.bashrc_local
      echo '# Adding  any /bin under __^S^__ALTERAOCLSDKROOT or __^S^__INTELFPGAOCLSDKROOT to __^S^__PATH if applicable' >> ~/.bashrc_local
      echo '#export LM_LICENSE_FILE=<path_to_license_file>' >> ~/.bashrc_local
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
fi

echo "--------------------------------------------------"
if [ ${auto} -eq 1 ]; then
  ok="y"
else
  read -p "Install Verilator+CoCoTB+TerosHDL (y/n)? " ok
fi
if [ "${ok}" == "y" ]; then
  echo "Installing Verilator"
  # App dependencies
  sudo -S apt purge -y verilator
  sudo -S apt install -y perl g++
  sudo -S apt install -y autoconf flex bison
  sudo -S apt install -y libfl2 libfl-dev zlib1g zlib1g-dev
  sudo -S apt install -y ccache libgoogle-perftools-dev numactl perl-doc
  
  # Check if directory exists
  cd ${HOME}/repos
  if [ ! -d "verilator" ]; then
    git clone https://github.com/eideticom/verilator.git
    cd verilator
    git remote add upstream https://github.com/verilator/verilator.git
    git fetch upstream
    cd ..
  fi
  
  # Setup env
  unset VERILATOR_ROOT
  cd verilator
  git checkout master
  git fetch; git pull
  if [ -z "${verilator_tag}" ]; then
    verilator_tag=$(git describe --abbrev=0)
  fi
  git checkout ${verilator_tag}
  
  # Install App
  autoconf
  ./configure --prefix ${HOME}/tools/verilator
  make -j$(nproc)
  sudo -S make install
  
  if ! grep -q "verilator" "${HOME}/.bashrc_local"; then
    echo '# --------------------------------' >> ~/.bashrc_local
    echo '# verilator' >> ~/.bashrc_local
    echo 'export PATH=${HOME}/tools/verilator/bin:$PATH' >> ~/.bashrc_local
  fi
  
  echo "--------------------------------------------------"
  echo "Installing CoCoTB (https://docs.cocotb.org/en/stable/)"
  # VirtualEnv
  source $HOME/.local/bin/virtualenvwrapper.sh
  echo "--------------------------------------------------"
  python=${VIRTUAL_ENV}
  if [ -z ${python} ]; then
    read -p "No virtualenv active detected, use virtualenv:dev (y/n)? " ok
    if [ "${ok}" == "y" ]; then
      source .virtualenvs/dev/bin/activate
    else
      read -p "Create/use virtualenv:hdl (y/n)? " ok
      if [ "${ok}" == "y" ]; then
        if [ ! -d "${HOME}/.virtualenvs/hdl/" ]; then
          echo "virtualenv:hdl not found, creating..."
          mkvirtualenv hdl
          source .virtualenvs/hdl/bin/activate
          pip install -r ~/dev/devsetup/virtualenv/dev_requirements.txt
          pip install -r ~/dev/devsetup/virtualenv/pytest_requirements.txt
        else
          source .virtualenvs/hdl/bin/activate
        fi
      else
        echo "This scripts only with virtualenv"
        exit 1
      fi
    fi
  fi
  pip install cocotb cocotb-test cocotb-coverage
  
  # cocotb-bus
  # -> verilator/cocotb currently only works with bus v0.1.0
  cd ${HOME}/repos
  if [ ! -d "cocotb-bus" ]; then
    git clone https://github.com/cocotb/cocotb-bus.git
  fi
  cd cocotb-bus
  git checkout ${cocotb_bus_tag}
  pip install -e ./
  
  # cocotbext-pcie
  cd ${HOME}/repos
  if [ ! -d "cocotbext-pcie" ]; then
    git clone https://github.com/Eideticom/cocotbext-pcie.git
    cd cocotbext-pcie
    git remote add upstream https://github.com/alexforencich/cocotbext-pcie.git
    git fetch upstream
    cd ..
  fi
  cd cocotbext-pcie
  git checkout ${cocotbext_pcie_tag}
  pip install -e ./
  
  # cocotbext-axi
  cd ${HOME}/repos
  if [ ! -d "cocotbext-axi" ]; then
    git clone https://github.com/Eideticom/cocotbext-axi.git
    cd cocotbext-pcie
    git remote add upstream https://github.com/alexforencich/cocotbext-axi.git
    git fetch upstream
    cd ..
  fi
  cd cocotbext-axi
  git checkout ${cocotbext_axi_tag}
  pip install -e ./
  
  echo "--------------------------------------------------"
  if [ ${auto} -eq 1 ]; then
    ok="y"
  else
    read -p "Install VisualCode TerosHDL (https://terostechnology.github.io/terosHDLdoc/) (y/n)? " ok
  fi
  if [ "${ok}" == "y" ]; then
    pip install teroshdl
    code --install-extension teros-technology.teroshdl
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
