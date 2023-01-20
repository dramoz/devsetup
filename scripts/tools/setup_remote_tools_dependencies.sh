
#!/bin/bash
# --------------------------------------------------------------------------------
VENV_TGT="dev"
xlnx_tools_ver="2022.2"
intel_quartus_ver="22.3"

intel_questa_ver="${intel_quartus_ver}"
# --------------------------------------------------------------------------------
echo "---------------------------------------------------------"
echo "-> Please make sure that ./ubuntu_setup.sh was run before!!"
read -p "Continue (y/n)? " ok
if [ "${ok}" != "y" ]; then
  exit 1
fi
echo "--------------------------------------------------"

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
sudo -S apt update -y && sudo -S apt upgrade -y && sudo -S apt dist-upgrade -y && sudo -S apt autoremove -y

echo "--------------------------------------------------"
# R&D dirs
echo "Creating common dirs..."
cd ~; mkdir -p dev tools repos tmp

echo "----------------------------------------------------------------------------------------------------"
# VirtualEnv
source $HOME/.local/bin/virtualenvwrapper.sh
echo "--------------------------------------------------"
python=${VIRTUAL_ENV}
if [ -z ${python} ]; then
  read -p "No virtualenv active detected, create/use virtualenv:${VENV_TGT} (y/n)? " ok
  if [ "${ok}" == "y" ]; then
    if [ ! -d "${HOME}/.virtualenvs/${VENV_TGT}/" ]; then
      echo "virtualenv:${VENV_TGT} not found, creating..."
      mkvirtualenv ${VENV_TGT}
      source .virtualenvs/${VENV_TGT}/bin/activate
    else
      source .virtualenvs/${VENV_TGT}/bin/activate
    fi
  fi
fi

echo "----------------------------------------------------------------------------------------------------"
read -p "Do a python requirements (dev, pytest) update (y/n)? " ok
if [ "${ok}" == "y" ]; then
  pip install --upgrade pip setuptools virtualenv
  pip install -r ~/dev/devsetup/virtualenv/dev_requirements.txt
  #pip install -r ~/dev/devsetup/virtualenv/hdl_requirements.txt
  pip install -r ~/dev/devsetup/virtualenv/pytest_requirements.txt
fi

echo "----------------------------------------------------------------------------------------------------"
read -p "Setup Xilinx tools (y/n)? " ok
  if [ "${ok}" == "y" ]; then
    if ! grep -q "xilinx" "${HOME}/.bashrc_local"; then
    echo '# --------------------------------' >> ~/.bashrc_local
    echo '# xilinx' >> ~/.bashrc_local
    echo "export XILINX_DIR=\"\${TOOLS_PATH}/Xilinx\"" >> ~/.bashrc_local
    echo "export XILINX_VER=\"${xlnx_tools_ver}\"" >> ~/.bashrc_local
    echo '#export XILINXD_LICENSE_FILE=${HOME}/tools/xilinx/license.dat' >> ~/.bashrc_local
  fi
  sudo -S ${TOOLS_PATH}/Xilinx/Vitis/${xlnx_tools_ver}/scripts/installLibs.sh
fi

echo "----------------------------------------------------------------------------------------------------"
read -p "Quartus Pro (y/n)? " ok
if [ "${ok}" == "y" ]; then
  if ! grep -q "quartus" "${HOME}/.bashrc_local"; then
    echo '# --------------------------------' >> ~/.bashrc_local
    echo '# quartus' >> ~/.bashrc_local
    echo "export QUARTUS_ROOTDIR=\"\${TOOLS_PATH}/intelFPGA_pro/${intel_quartus_ver}/quartus\"" >> ~/.bashrc_local
    echo 'export QSYS_ROOTDIR=$QUARTUS_ROOTDIR/qsys/bin' >> ~/.bashrc_local
    echo 'export PATH=$QUARTUS_ROOTDIR/bin:$PATH' >> ~/.bashrc_local
    echo 'export LM_LICENSE_FILE=${HOME}/tools/intel/license.dat' >> ~/.bashrc_local
  fi
  sudo -S apt install libncurses5
fi

echo "----------------------------------------------------------------------------------------------------"
read -p "Questa (Pro) (y/n)? " ok
if [ "${ok}" == "y" ]; then
  if ! grep -q "questa" "${HOME}/.bashrc_local"; then
    echo '# --------------------------------' >> ~/.bashrc_local
    echo '# questa' >> ~/.bashrc_local
    echo "export QUESTA_ROOTDIR=\"\${TOOLS_PATH}/intelFPGA_pro/${intel_questa_ver}/questa_fe\"" >> ~/.bashrc_local
    echo 'export PATH=$QUESTA_ROOTDIR/bin:$PATH' >> ~/.bashrc_local
    echo '#export LM_LICENSE_FILE=${HOME}/tools/intel/license.dat' >> ~/.bashrc_local
  fi
  sudo -S apt install libncurses5
fi

echo "----------------------------------------------------------------------------------------------------"
read -p "Quartus Lite (y/n)? " ok
if [ "${ok}" == "y" ]; then
  if ! grep -q "quartus" "${HOME}/.bashrc_local"; then
    echo '# --------------------------------' >> ~/.bashrc_local
    echo '# quartus' >> ~/.bashrc_local
    echo "export QUARTUS_ROOTDIR=\"\${TOOLS_PATH}/intelFPGA_lite/${intel_quartus_ver}/quartus\"" >> ~/.bashrc_local
    echo 'export QSYS_ROOTDIR=$QUARTUS_ROOTDIR/qsys/bin' >> ~/.bashrc_local
    echo 'export PATH=$QUARTUS_ROOTDIR/bin:$PATH' >> ~/.bashrc_local
    echo '#export LM_LICENSE_FILE=${HOME}/tools/intel/license.dat' >> ~/.bashrc_local
  fi
  sudo -S apt install libncurses5
fi

echo "----------------------------------------------------------------------------------------------------"
read -p "CMake (y/n)? " ok
if [ "${ok}" == "y" ]; then
  sudo -S apt install libssl-dev ninja-build
fi

echo "----------------------------------------------------------------------------------------------------"
read -p "Slang (y/n)? " ok
if [ "${ok}" == "y" ]; then
  sudo -S apt install libssl-dev
fi

echo "----------------------------------------------------------------------------------------------------"
read -p "Verilator/CoCoTB (y/n)? " ok
if [ "${ok}" == "y" ]; then
  sudo -S apt install -y perl g++
  sudo -S apt install -y autoconf flex bison
  sudo -S apt install -y libfl2 libfl-dev zlib1g zlib1g-dev
  sudo -S apt install -y ccache libgoogle-perftools-dev numactl perl-doc
fi

echo "----------------------------------------------------------------------------------------------------"
read -p "VexRiscV (scala-sbt) (y/n)? " ok
if [ "${ok}" == "y" ]; then
  sudo -S apt install -y openjdk-8-jdk
  sudo -S apt install -y scala
  echo "deb https://repo.scala-sbt.org/scalasbt/debian all main" | sudo -S tee /etc/apt/sources.list.d/sbt.list
  echo "deb https://repo.scala-sbt.org/scalasbt/debian /" | sudo -S tee /etc/apt/sources.list.d/sbt_old.list
  curl -sL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x2EE0EA64E40A89B84B2DF73499E82A75642AC823" | sudo -S apt-key add
  sudo -S apt update -y
  sudo -S apt install -y sbt
fi

#echo "----------------------------------------------------------------------------------------------------"
#read -p "Install APP (https://app.org/) (y/n)? " ok
#if [ "${ok}" == "y" ]; then
#  echo ".................................................."
#  echo "sudo -S app_requirements"
#  echo "pip install app_requirements"
#  echo "install_app"
#fi

echo "----------------------------------------------------------------------------------------------------"
echo "Done"
echo "----------------------------------------------------------------------------------------------------"
