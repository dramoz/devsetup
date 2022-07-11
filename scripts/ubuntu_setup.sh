#!/bin/bash
echo "--------------------------------------------------"
echo "The following script will do a custom install of the required apps for R&D, and then reboot"
echo "--------------------------------------------------"
read_data=true
while $read_data; do
  read -p 'Name LastName: ' full_name
  read -p 'github email: ' email
  echo "--------------------------------------------------"
  echo "${full_name}: ${email}"
  read -p "OK (y/n)? " ok
  if [ "${ok}" == "y" ]; then
    read_data=false
  else
    read_data=true
  fi
done

# remove virtualenv and virtualenvwrapper from Ubuntu apt
echo "--------------------------------------------------"
echo "Removing default Ubuntu virtualenv/virtualenvwrapper"
sudo -S apt purge -y virtualenv
sudo -S apt purge -y virtualenvwrapper

# Ubuntu update
echo "--------------------------------------------------"
echo "update/upgrade/remove"
sudo -S apt update -y; sudo apt upgrade -y; sudo apt autoremove -y

# For USB/UART serial access
echo "--------------------------------------------------"
echo "${USER}->dialout"
sudo -S adduser $USER dialout

# R&D dirs
echo "--------------------------------------------------"
echo "Creating common dirs..."
cd ~; mkdir -p dev tools repos

# Required apps
echo "--------------------------------------------------"
echo "apt required tools..."
sudo -S apt install -y build-essential git graphviz gtkwave screen tmux tree vim python3 python3-pip python3-tk meld

# Setup git credentials
echo "--------------------------------------------------"
echo "git config..."
git config --global user.email "${email}"
git config --global user.name "${full_name}"

# SSH key for GitHub
echo "--------------------------------------------------"
echo "GitHub ssh-key"
ssh-keygen -t ed25519 -C "${email}"
ssh-add ~/.ssh/id_ed25519
echo "Copy/paste (and create key at GitHub) ->"
cat ~/.ssh/id_ed25519.pub
firefox -new-window https://github.com/settings/keys

echo "--------------------------------------------------"
read_data=true
while $read_data; do
  read -p "Did you added the key (y/n)? " ok
  if [ "${ok}" == "y" ]; then
    read_data=false
  else
    read_data=true
  fi
done

# Guest Additions...
echo "--------------------------------------------------"
vboxguest=$(lsmod | grep vboxguest)
if [ ! -z "${vboxguest}" ]; then
  read -p "It looks this is a VM, let's install Guest Additions (y/n)? " ok
  if [ "${ok}" == "y" ]; then
    echo "From VM menu"
    echo "-> Devices.Insert Guest Additions, and click [RUN]"
    read -p "Press [ENTER] key after Guest Additions is done..." ok
    echo "Don't forget to [EJECT] Guest Additions CD/ISO"
    sudo adduser $USER vboxsf
  
  else
    echo "Please install guest additions later..."
  fi
fi

echo "--------------------------------------------------"
read -p "Done for the moment, reboot (y/n)? " ok
if [ "${ok}" == "y" ]; then
  sudo reboot
else
  echo "Please reboot at your convenience..."
fi

