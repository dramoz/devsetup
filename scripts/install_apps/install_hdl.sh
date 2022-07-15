#!/bin/bash
echo "---------------------------------------------------------"
echo "This script will setup tools/apps for HDL R&D (e.g. SystemVerilog, VS-Code plugings, ...)"
echo "-> Please make sure that ./ubuntu_setup.sh and ~/dev/devsetup/dev_setup.sh were ran before!!"
read -p "Continue (y/n)? " ok
if [ "${ok}" == "n" ]; then
  exit 1
fi

# VirtualEnv
source $HOME/.local/bin/virtualenvwrapper.sh

echo "--------------------------------------------------"
python=$(which python)
python_cmd="python"
pip_cmd="pip"
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

# Dependencies
sudo -S apt install -y build-essential uuid-dev cmake default-jre python3 python3-dev python3-pip libantlr4-runtime-dev antlr4 ninja-build

echo "--------------------------------------------------"
echo "Installing CoCoTB (https://docs.cocotb.org/en/stable/)"
pip install -r ~/dev/devsetup/virtualenv/hdl_requirements.txt

echo "--------------------------------------------------"
echo "Installing/checking Verilator (simulation and linting) (https://www.veripool.org/verilator/)"
~/dev/devsetup/scripts/install_apps/install_verilator.sh ~/repos v4.224.1

echo "--------------------------------------------------"
read -p "Install VisualCode TerosHDL (https://terostechnology.github.io/terosHDLdoc/) (y/n)? " ok
if [ "${ok}" == "y" ]; then
  pip install teroshdl
  code --install-extension teros-technology.teroshdl
fi

echo "--------------------------------------------------"
echo "Done!!!"
echo "--------------------------------------------------"
