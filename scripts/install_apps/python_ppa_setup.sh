
#!/bin/bash
# https://launchpad.net/~deadsnakes/+archive/ubuntu/ppa
# --------------------------------------------------------------------------------
VENV_TGT="dev"
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
echo "Add repository "
sudo -S add-apt-repository ppa:deadsnakes/ppa
sudo -S apt update -y
sudo -S apt install -y dirmngr ca-certificates software-properties-common apt-transport-https

echo "----------------------------------------------------------------------------------------------------"
echo "Done"
echo "do: sudo apt install -y python3.8 ..."
echo "----------------------------------------------------------------------------------------------------"
