#!/bin/bash
# --------------------------------------------------------------------------------
# Tools versions
risv_toolchain_ver="10.2.0-2020.12.8-x86_64-linux-ubuntu14"

# --------------------------------------------------------------------------------
echo "---------------------------------------------------------"
echo "-> Please make sure that ./ubuntu_setup.sh was run before!!"
echo "--------------------------------------------------"
read -p "Install RISC-V toolchain (SiFive) (y/n)? " ok

if [ "${ok}" != "y" ]; then
  exit 1
fi

#echo "----------------------------------------------------------------------------------------------------"
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
# RISC-V toolchain
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

echo "--------------------------------------------------"
read -p "Done for the moment, reboot (y/n)? " ok
if [ "${ok}" == "y" ]; then
  echo "Sanity reboot..."
  sudo reboot
fi
