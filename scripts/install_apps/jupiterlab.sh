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
  read -p "No virtualenv active detected, create/use virtualenv:jupyter (y/n)? " ok
  if [ "${ok}" == "y" ]; then
    if [ ! -d "${HOME}/.virtualenvs/jupyter/" ]; then
      echo "virtualenv:jupyter not found, creating..."
      mkvirtualenv jupyter
      source .virtualenvs/jupyter/bin/activate
    else
      source .virtualenvs/jupyter/bin/activate
    fi
  else
    echo "This scripts only with virtualenv"
    exit 1
  fi
fi

echo "----------------------------------------------------------------------------------------------------"
echo "Installing python requirements and jupyter extensions..."
pip install -r ~/dev/devsetup/virtualenv/dev_requirements.txt
pip install -r dev/devsetup/virtualenv/jupyterlab_requirements.txt 
jupyter labextension install @jupyterlab/toc

echo "----------------------------------------------------------------------------------------------------"
# https://launchpad.net/~ppa-verse/+archive/ubuntu/cling
echo "--------------------------------------------------"
read -p "Instal cling kernel (C++) (y/n)? " ok
if [ "${ok}" == "y" ]; then
  pip install xeus-python
  #f
  
  ppa:ppa-verse/xeus-cling
  #sudo -S apt update
  #sudo -S apt install -y cling
fi
