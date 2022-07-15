#!/bin/bash
echo "---------------------------------------------------------"
echo "This script will setup tools/apps for Embedded R&D"
echo "-> Please make sure that ./ubuntu_setup.sh was run before!!"
read -p "Continue (y/n)? " ok
if [ "${ok}" == "n" ]; then
  exit 1
fi

echo "--------------------------------------------------"
sudo -S apt install -y nodejs

# Python virtualenv
echo "--------------------------------------------------"
echo "Installing Python virtualenv/virtualenvwrapper"
pip3 install virtualenv virtualenvwrapper

# DevSetup
echo "--------------------------------------------------"
if [ ! -d "${HOME}/dev/devsetup" ]; then
  echo "Cloning GitHub dramoz/devsetup and set .bash*"
  cd ~/dev
  git clone git@github.com:dramoz/devsetup.git
fi

echo "--------------------------------------------------"
read -p "Update .bashrc with <devsetup> (y/n)? " ok
if [ "${ok}" == "y" ]; then
  cd ~/dev/devsetup; git pull; cd ~
  cp ~/dev/devsetup/scripts/.bashrc ~/.bashrc
  if [ ! -f "${HOME}/.bashrc_local" ]; then
    echo "devsetup: .bashrc can load local configurations from ~/.bashrc_local (${HOME}/.bashrc_local)"
    echo "As no .bashrc_local file found, copying a base example"
    cp ~/dev/devsetup/scripts/.bashrc_local ~/.bashrc_local
  fi
  source ~/.bashrc
fi

# Virtualenv:dev
source $HOME/.local/bin/virtualenvwrapper.sh
echo "--------------------------------------------------"
if [ ! -d "${HOME}/.virtualenvs/dev/" ]; then
  echo "virtualenv:dev not found, creating..."
  mkvirtualenv dev
fi

echo "Adding requirements to virtualenv:dev"
source .virtualenvs/dev/bin/activate
pip install -r ~/dev/devsetup/virtualenv/dev_requirements.txt
pip install -r ~/dev/devsetup/virtualenv/pytest_requirements.txt

echo "--------------------------------------------------"
read -p "Add JupyterLab to virtualdev:dev (y/n)? " ok
if [ "${ok}" == "y" ]; then
  pip install -r ~/dev/devsetup/virtualenv/jupyterlab_requirements.txt
fi

echo "--------------------------------------------------"
read -p "Add CoCoTB requirements to virtualdev:dev (y/n)? " ok
if [ "${ok}" == "y" ]; then
  pip install -r ~/dev/devsetup/virtualenv/hdl_requirements.txt
fi

echo "--------------------------------------------------"
read -p "Add ML (machine learning with OpenCV) requirements to virtualdev:dev (y/n)? " ok
if [ "${ok}" == "y" ]; then
  pip install -r ~/dev/devsetup/virtualenv/ml_requirements.txt
fi

echo "--------------------------------------------------"
read -p "Install VS code (y/n)? " ok
if [ "${ok}" == "y" ]; then
  sudo -S snap install code --classic
fi

echo "--------------------------------------------------"
read -p "Done for the moment, reboot (y/n)? " ok
if [ "${ok}" == "y" ]; then
  sudo reboot
else
  echo "Please reboot at your convenience..."
fi

