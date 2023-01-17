#!/bin/bash
# --------------------------------------------------------------------------------
# Tools versions

# --------------------------------------------------------------------------------
echo "---------------------------------------------------------"
echo "-> Please make sure that ./ubuntu_setup.sh was run before!!"
read -p "Continue (y/n)? " ok
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
    fi
  fi
fi

echo "--------------------------------------------------"
read -p "VS Code Platform.IO (https://platformio.org/) (y/n)? " ok
if [ "${ok}" == "y" ]; then
  code --install-extension platformio.platformio-ide
fi

echo "--------------------------------------------------"
read -p "Done for the moment, reboot (y/n)? " ok
if [ "${ok}" == "y" ]; then
  echo "Sanity reboot..."
  sudo reboot
fi
