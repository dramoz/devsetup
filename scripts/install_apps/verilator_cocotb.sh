#!/bin/bash
# --------------------------------------------------------------------------------
# Tools versions
verilator_tag="v4.228.1"
cocotb_ver="1.7.1"
cocotb_bus_ver="v0.1.0"
cocotbext_pcie_tag="eid"
cocotbext_axi_tag="master"
# --------------------------------------------------------------------------------
echo "---------------------------------------------------------"
echo "-> Please make sure that ./ubuntu_setup.sh was run before!!"
echo "--------------------------------------------------"
read -p "Install Verilator(${verilator_tag}), CoCoTB(${cocotb_ver}), CoCoTB.bus(${cocotb_bus_ver}) and CoCoTB.Ext.PCIe(${cocotbext_pcie_tag})/AXI(${cocotbext_axi_tag}) (y/n)? " ok
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
git checkout ${verilator_tag}

# Install App
autoconf
./configure --prefix ${HOME}/tools/verilator
make -j$(nproc)
make install

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
      else
        source .virtualenvs/hdl/bin/activate
      fi
    else
      echo "This scripts only with virtualenv"
      exit 1
    fi
  fi
fi
pip install -r ~/dev/devsetup/virtualenv/pytest_requirements.txt
pip install cocotb==${cocotb_ver} cocotb-bus==${cocotb_bus_ver}
pip install cocotb-test cocotb-coverage

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
read -p "Done for the moment, reboot (y/n)? " ok
if [ "${ok}" == "y" ]; then
  echo "Sanity reboot..."
  sudo reboot
fi
