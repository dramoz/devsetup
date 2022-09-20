#!/bin/bash
echo "----------------------------------------------------------------------------------------------------"
auto=0
if [ ! -z "$1" ]; then
  if [ "$1" == "y" ]; then
    echo "Running the script in partial auto/all mode"
    echo "Installing:"
    echo " build-essential+python+..."
    echo " setup virtualenv/virtualenvwrapper through pip"
    echo " setup GIT and GitHub SSH"
    echo " clone dramoz/devsetup.git and setup .bashrc"
    echo " install code/brave/pyGrid"
    echo "Note: user intervention required for Vbox guess install"
    echo "--------------------------------------------------"
    read -p "Proceed (y/n)? " ok
    if [ "${ok}" == "y" ]; then
      auto=1
    fi
    echo "----------------------------------------------------------------------------------------------------"
  fi
fi

if [ "${auto}" == "0" ]; then
  echo "The following script will do a custom install of the required apps for R&D, and then reboot"
  echo "----------------------------------------------------------------------------------------------------"
fi

echo "----------------------------------------------------------------------------------------------------"
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
sudo -S apt update -y && sudo -S apt upgrade -y && sudo apt dist-upgrade -y && sudo apt autoremove -y

# For USB/UART serial access
echo "--------------------------------------------------"
echo "${USER}->dialout"
sudo -S adduser $USER dialout

# R&D dirs
echo "--------------------------------------------------"
echo "Creating common dirs..."
cd ~; mkdir -p dev tools repos tmp

# Required apps
echo "--------------------------------------------------"
echo "apt required tools..."
sudo -S apt install -y build-essential git graphviz gtkwave screen tmux tree vim
sudo -S apt install -y python3 python3-pip python3-tk meld nodejs
sudo -S apt install -y gnome-shell-extensions chrome-gnome-shell

# Setup git credentials
echo "--------------------------------------------------"
echo "git config..."
git config --global user.email "${email}"
git config --global user.name "${full_name}"

# SSH key for GitHub
echo "--------------------------------------------------"
ssh_key="${HOME}/.ssh/id_ed25519"
if [ ! -f "${ssh_key}" ]; then
  echo "Creating GitHub ssh-key"
  ssh-keygen -t ed25519 -C "${email}"
  ssh-add ~/.ssh/id_ed25519
  echo "Copy/paste (and create key at GitHub) ->"
  cat ~/.ssh/id_ed25519.pub
  firefox -new-window https://github.com/settings/keys
  
  echo "--------------------------------------------------"
  read_data=true
  while $read_data; do
    read -p "Press <y> after adding the key to GitHub (https://github.com/settings/keys)" ok
    if [ "${ok}" == "y" ]; then
      read_data=false
    else
      read_data=true
    fi
  done
fi

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
# Python virtualenv
echo "--------------------------------------------------"
echo "Installing Python virtualenv/virtualenvwrapper"
pip3 install virtualenv virtualenvwrapper

# DevSetup
echo "--------------------------------------------------"
if [ ${auto} -eq 1 ]; then
  ok="y"
else
  read -p "Clone and update .bashrc with <devsetup> (y/n)? " ok
fi

if [ "${ok}" == "y" ]; then
  if [ ! -d "${HOME}/dev/devsetup" ]; then
    echo "Cloning GitHub dramoz/devsetup and set .bash*"
    cd ~/dev
    git clone git@github.com:dramoz/devsetup.git
  fi

  echo "--------------------------------------------------"

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
if [ ${auto} -eq 1 ]; then
  ok="y"
else
  read -p "Install VS code (y/n)? " ok
fi

if [ "${ok}" == "y" ]; then
  echo "Installing VS Code"
  sudo -S snap install code --classic
  
  echo "--------------------------------------------------"
  if [ ${auto} -eq 1 ]; then
    ok="y"
  else
    read -p "Install VS code extensions (y/n)? " ok
  fi
  if [ "${ok}" == "y" ];  then
    echo "Installing VS Code extensions"
    while IFS= read -r line; do
      code --install-extension ${line}
    done < ${HOME}/dev/devsetup/scripts/assets/code.ext
  fi
fi

echo "--------------------------------------------------"
if [ ${auto} -eq 1 ]; then
  ok="y"
else
  read -p "Install pyGrid (https://github.com/pkkid/pygrid) (y/n)? " ok
fi

if [ "${ok}" == "y" ]; then
  echo "Installing pyGrid"
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
if [ ${auto} -eq 1 ]; then
  ok="y"
else
  read -p "Install Brave Browser (chromium alternative) (y/n)? " ok
fi
if [ "${ok}" == "y" ]; then
  echo "Installing Brave browser"
  sudo -S apt -y install apt-transport-https curl
  sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
  echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg arch=amd64] https://brave-browser-apt-release.s3.brave.com/ stable main"|sudo tee /etc/apt/sources.list.d/brave-browser-release.list
  sudo -S apt update -y
  sudo -S apt install -y brave-browser
fi

echo "--------------------------------------------------"
echo "--------------------------------------------------"
if [ ${auto} -eq 1 ]; then
  ok="y"
else
  read -p "Done for the moment, reboot (y/n)? " ok
fi
if [ "${ok}" == "y" ]; then
  echo "Sanity reboot..."
  sudo reboot
fi
