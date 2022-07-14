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

echo "--------------------------------------------------"
read -p "Install CoCoTB (https://docs.cocotb.org/en/stable/) (y/n)? " ok
if [ "${ok}" == "y" ]; then
  pip install -r ~/dev/devsetup/virtualenv/cocotb_requirements.txt
fi

echo "--------------------------------------------------"
read -p "Install VisualCode TerosHDL (https://terostechnology.github.io/terosHDLdoc/) (y/n)? " ok
if [ "${ok}" == "y" ]; then
  pip install teroshdl
  code --install-extension teros-technology.teroshdl
fi

echo "--------------------------------------------------"
read -p "Install Verilator (simulation and linting) (https://www.veripool.org/verilator/) (y/n)? " ok
if [ "${ok}" == "y" ]; then
  ~/dev/devsetup/scripts/install_apps/install_verilator.sh ~/repos v4.224.1
fi

echo "--------------------------------------------------"
echo "Done!!!"
echo "--------------------------------------------------"
