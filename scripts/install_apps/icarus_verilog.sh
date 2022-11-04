#!/bin/bash
# --------------------------------------------------------------------------------
# Tools versions
iverilog_tag="v11_0"
# --------------------------------------------------------------------------------
echo "---------------------------------------------------------"
echo "-> Please make sure that ./ubuntu_setup.sh was run before!!"
echo "--------------------------------------------------"
read -p "Install Icarus-Verilog ver:${iverilog_tag} (y/n)? " ok
if [ "${ok}" != "y" ]; then
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

# Ubuntu update
echo "--------------------------------------------------"
echo "update/upgrade/remove"
sudo -S apt update -y && sudo -S apt upgrade -y && sudo apt dist-upgrade -y && sudo apt autoremove -y

# R&D dirs
echo "--------------------------------------------------"
echo "Creating common dirs..."
cd ~; mkdir -p dev tools repos tmp

echo "--------------------------------------------------"
echo "Installing Icarus-Verilog (https://iverilog.fandom.com/wiki/Main_Page)"
# App dependencies
sudo -S apt install -y autoconf gperf

cd ${HOME}/repos
if [ ! -d "iverilog" ]; then
  git clone https://github.com/steveicarus/iverilog.git
fi

cd iverilog
git checkout $iverilog_tag
bash autoconf.sh
./configure --prefix=${HOME}/tools/iverilog
make -j$(nproc)
sudo -S make install
iverilog -v

echo "--------------------------------------------------"
read -p "Done for the moment, reboot (y/n)? " ok
if [ "${ok}" == "y" ]; then
  echo "Sanity reboot..."
  sudo reboot
fi
