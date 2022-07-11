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
if [ -d "~/dev/devsetup" ]; then
  echo "Cloning GitHub dramoz/devsetup and set .bash*"
  cd ~/dev
  git clone git@github.com:dramoz/devsetup.git
fi

cd ~/dev/devsetup; git pull; cd ~
cp ~/dev/devsetup/scripts/.bashrc ~/.bashrc
. ~/.bashrc

# Virtualenv:dev
echo "--------------------------------------------------"
echo "Creating virtualenv:dev"
mkvirtualenv dev
pip install -r ~/dev/devsetup/virtualenv/dev_requirements.txt
pip install -r ~/dev/devsetup/virtualenv/pytest_requirements.txt

echo "--------------------------------------------------"
read -p "Add JupyterLab to virtualdev:dev (y/n)? " ok
if [ "${ok}" == "y" ]; then
  pip install -r ~/dev/devsetup/virtualenv/jupyter_requirements.txt
fi

echo "--------------------------------------------------"
read -p "Add CoCoTB requirements to virtualdev:dev (y/n)? " ok
if [ "${ok}" == "y" ]; then
  pip install -r ~/dev/devsetup/virtualenv/cocotb_requirements.txt
fi

echo "--------------------------------------------------"
read -p "Add ML (machine learning with OpenCV) requirements to virtualdev:dev (y/n)? " ok
if [ "${ok}" == "y" ]; then
  pip install -r ~/dev/devsetup/virtualenv/ml_requirements.txt
fi

echo "--------------------------------------------------"
echo "Installing VS code..."
sudo -S snap install code --classic

echo "--------------------------------------------------"
read -p "Done for the moment, reboot (y/n)? " ok
if [ "${ok}" == "y" ]; then
  sudo reboot
else
  echo "Please reboot at your convenience..."
fi

