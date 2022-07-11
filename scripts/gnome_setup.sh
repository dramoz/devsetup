#!/bin/bash
echo "---------------------------------------------------------"
echo "This script will install required Apps. for Embedded R&D"
echo "-> Please make sure that ./ubuntu_setup.sh was run before!!"
read -p "Continue (y/n)? " ok
if [ "${ok}" == "n" ]; then
  exit 1
fi

echo "--------------------------------------------------"
echo "Installing gnome-shell-extensions..."
sudo -S apt install gnome-shell-extensions chrome-gnome-shell

# https://www.addictivetips.com/ubuntu-linux-tips/back-up-the-gnome-shell-desktop-settings-linux/
dconf_bk=${HOME}/dev/devsetup/scripts/assets/dconf-settings.ini
if [ -f "${dconf_bk}" ]; then
  read -p "Restore dconf preferences (y/n)? " ok
  if [ "${ok}" == "y" ]; then
    sudo -S apt install dconf*
    cd ~/
    dconf load / < ${dconf_bk}
  fi
else
  echo "${dconf_bk} file not found, skipping dconf restore"
fi

echo "--------------------------------------------------"
read -p "Install pyGrid (https://github.com/pkkid/pygrid) (y/n)? " ok
if [ "${ok}" == "y" ]; then
  sudo apt -y install git python3-gi python3-xlib
  cd ~/repos
  git clone https://github.com/mjs7231/pygrid.git
  cp ~/dev/devsetup/scripts/assets/pygrid/pygrid.py.desktop ~/.config/autostart/pygrid.py.desktop
  cp ~/dev/devsetup/scripts/assets/pygrid/pygrid.json ~/.config/pygrid.json
fi

echo "--------------------------------------------------"
echo "Installing desktop links"
cp ~/dev/devsetup/scripts/assets/Desktop/* ~/Desktop/

echo "--------------------------------------------------"
read -p "Install Brave Browser (y/n)? " ok
if [ "${ok}" == "y" ]; then
  sudo -S apt -y install apt-transport-https curl
  sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
  echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg arch=amd64] https://brave-browser-apt-release.s3.brave.com/ stable main"|sudo tee /etc/apt/sources.list.d/brave-browser-release.list
  sudo -S apt update -y
  sudo -S apt install -y brave-browser
fi

echo "--------------------------------------------------"
read -p "Done for the moment, reboot (y/n)? " ok
if [ "${ok}" == "y" ]; then
  sudo reboot
else
  echo "Please reboot at your convenience..."
fi

