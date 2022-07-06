#!/bin/bash
echo "The following script will do a custom install of the required apps for R&D, and then reboot"
read_data=true
while $read_data; do
  read -p 'Name LastName: ' full_name
  read -p 'github email: ' email
  echo "${full_name}: ${email}"
  read -p "OK? (y/n)" ok
  if [ ok == 'y' ]; then
    read_data=false
  else
    read_data=true
  fi
done

# remove virtualenv and virtualenvwrapper from Ubuntu apt
echo "Removing default Ubuntu virtualenv/virtualenvwrapper"
sudo -S apt purge -y virtualenv
sudo -S apt purge -y virtualenvwrapper

# Ubuntu update
echo "update/upgrade/remove"
sudo -S apt update -y; sudo apt upgrade -y; sudo apt autoremove -y

# For USB/UART serial access
echo "${USER}->dialout"
sudo -S adduser $USER dialout

# R&D dirs
echo "Creating common dirs..."
cd ~; mkdir -p dev tools repos

# Required apps
echo "apt required tools..."
sudo -S apt install -y build-essential git graphviz gtkwave screen tmux tree vim python3 python3-pip python3-tk meld

# Setup git credentials
echo "git config..."
git config --global user.email "${email}"
git config --global user.name "${full_name}"

# SSH key for GitHub
echo "GitHub ssh-key"
ssh-keygen -t ed25519 -C "${email}"
ssh-add ~/.ssh/id_ed25519
echo "Copy/paste (and create key at GitHub) ->"
cat ~/.ssh/id_ed25519.pub
firefox -new-window https://github.com/settings/keys

read_data=true
while $read_data; do
  read -p "Key added? (y/n)" ok
  if [ ok == 'y' ]; then
    read_data=false
  else
    read_data=true
  fi
done

# DevSetup
echo "Cloning devsetup"
cd ~/dev
git clone git@github.com:dramoz/devsetup.git

# Guest Additions...
read -p "Install VirtualBox Guess Additions? (y/n)" ok
if [ ok == 'y' ]; then
  echo "From VM menu"
  echo "-> Devices.Insert Guest Additions... (and follow instructions)"
  read -p "Press any key after guest additions is done..." ok
  sudo adduser $USER vboxsf
else
  echo "Done..."
fi

sudo reboot
