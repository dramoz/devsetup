#!/bin/bash
# --------------------------------------------------------------------------------
VENV_TGT="dev"
# --------------------------------------------------------------------------------

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

echo "The following script will do a custom install of the required apps for R&D... (manual mode)"
# remove virtualenv and virtualenvwrapper from Ubuntu apt
echo "--------------------------------------------------"
echo "Removing default Ubuntu virtualenv/virtualenvwrapper"
sudo -S apt purge -y virtualenv
sudo -S apt purge -y virtualenvwrapper

# Ubuntu update
echo "--------------------------------------------------"
echo "update/upgrade/remove"
sudo -S apt update -y && sudo -S apt upgrade -y && sudo -S apt dist-upgrade -y && sudo -S apt autoremove -y

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
sudo -S apt install -y build-essential git graphviz screen tmux tree vim openssh-server net-tools keychain
if [ ${WSL} -eq 0 ]; then
  sudo -S apt install -y gtkwave libcanberra-gtk-module libcanberra-gtk3-module libcanberra-gtk-module:i386
else
  sudo -S apt install -y gtkwave libcanberra-gtk-module libcanberra-gtk3-module
fi

sudo -S apt install -y python3 python3-pip python3-tk meld
sudo -S snap install node --classic

echo "--------------------------------------------------"
read -p "GNOME setup (y/n)? " ok
if [ "${ok}" == "y" ]; then
  if [ ${WSL} -eq 0 ]; then
    sudo -S apt install -y gnome-shell-extensions chrome-gnome-shell gnome-shell-extension-manager
    if [ "`echo "${ubuntu_ver} < 22.04" | bc`" -eq 1 ]; then
      # required for Gnome extensions setup
      sudo apt install flatpak
      flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    fi
  fi
fi

# Setup git credentials
echo "----------------------------------------------------------------------------------------------------"
read -p "Setup GIT credentials (y/n)? " ok
if [ "${ok}" == "y" ]; then
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

  echo "--------------------------------------------------"
  echo "git config..."
  git config --global user.email "${email}"
  git config --global user.name "${full_name}"
  git config --global credential.helper 'cache --timeout 30000'
fi

# SSH key for GitHub
echo "--------------------------------------------------"
ssh_key="${HOME}/.ssh/id_ed25519"
if [ ! -f "${ssh_key}" ]; then
  echo "Creating GitHub ssh-key"
  ssh-keygen -t ed25519 -C "${email}"
  ssh-add ~/.ssh/id_ed25519
  echo "Copy/paste (and create key at GitHub) ->"
  cat ~/.ssh/id_ed25519.pub
  eval $browser "https://github.com/settings/keys" >/dev/null 2>&1
  
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

if [ ${WSL} -eq 0 ]; then
  # Guest Additions...
  echo "--------------------------------------------------"
  vboxguest=$(lsmod | grep vboxguest)
  if [ ! -z "${vboxguest}" ]; then
    read -p "It looks this is a VM, let's (re)install Guest Additions (y/n)? " ok
    if [ "${ok}" == "y" ]; then
      echo "From VM menu"
      echo "-> Devices.Insert Guest Additions, and click [RUN]"
      read -p "Press [ENTER] key after Guest Additions is done..." ok
      echo "Don't forget to [EJECT] Guest Additions CD/ISO"
      sudo adduser $USER vboxsf
    fi
  fi
  echo "--------------------------------------------------"
fi

# Python virtualenv
echo "--------------------------------------------------"
echo "Installing Python virtualenv/virtualenvwrapper"
pip3 install --upgrade virtualenv virtualenvwrapper

# DevSetup
echo "--------------------------------------------------"
read -p "Clone and update .bashrc with <devsetup> (y/n)? " ok
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

echo "----------------------------------------------------------------------------------------------------"
# VirtualEnv
source ~/.bashrc
source $HOME/.local/bin/virtualenvwrapper.sh
echo "--------------------------------------------------"
python=${VIRTUAL_ENV}
if [ -z ${python} ]; then
  read -p "No virtualenv active detected, create/use virtualenv:${VENV_TGT} (y/n)? " ok
  if [ "${ok}" == "y" ]; then
    if [ ! -d "${HOME}/.virtualenvs/${VENV_TGT}/" ]; then
      echo "virtualenv:${VENV_TGT} not found, creating..."
      mkvirtualenv ${VENV_TGT}
      source .virtualenvs/${VENV_TGT}/bin/activate
    else
      source .virtualenvs/${VENV_TGT}/bin/activate
    fi
  fi
fi

echo "Adding requirements to virtualenv:${VENV_TGT}"
source .virtualenvs/${VENV_TGT}/bin/activate
pip install -r ~/dev/devsetup/virtualenv/dev_requirements.txt
pip install -r ~/dev/devsetup/virtualenv/pytest_requirements.txt

echo "--------------------------------------------------"
read -p "Install VS code (y/n)? " ok
if [ "${ok}" == "y" ]; then
  echo "Installing VS Code"
  if [ ${WSL} -eq 0 ]; then
    sudo -S snap install code --classic
  else
    echo "Install Visual Code on Windows first..."
    eval $browser "https://code.visualstudio.com/Download" >/dev/null 2>&1
    read -p "VS Code installed (y/n)? " ok
    code
    code --install-extension ms-vscode-remote.remote-wsl
  fi
  
  echo "--------------------------------------------------"
  read -p "Install VS code extensions + user settings (select 'n' if using code sync) (y/n)? " ok
  if [ "${ok}" == "y" ];  then
    echo "Installing VS Code extensions (UI+Workspace)"
    while IFS= read -r line; do
      code --install-extension ${line}
    done < ${HOME}/dev/devsetup/scripts/assets/vscode/ui_extensions.ext
    
    while IFS= read -r line; do
      code --install-extension ${line}
    done < ${HOME}/dev/devsetup/scripts/assets/vscode/workspace_extensions.ext
    
    echo "Restoring user settings"
    cp ${HOME}/dev/devsetup/scripts/assets/vscode/*.json ${HOME}/.config/Code/User/
  fi
fi

if [ ${WSL} -eq 0 ]; then
  echo "--------------------------------------------------"
  read -p "Install GNOME desktop links (y/n)? " ok
  if [ "${ok}" == "y" ]; then
    echo "Installing desktop links"
    cp ~/dev/devsetup/scripts/assets/Desktop/* ~/Desktop/
  fi
  echo "--------------------------------------------------"
  read -p "Install Brave Browser (chromium alternative) (y/n)? " ok
  if [ "${ok}" == "y" ]; then
    echo "Installing Brave browser"
    sudo -S apt -y install apt-transport-https curl
    sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg arch=amd64] https://brave-browser-apt-release.s3.brave.com/ stable main"|sudo tee /etc/apt/sources.list.d/brave-browser-release.list
    sudo -S apt update -y
    sudo -S apt install -y brave-browser
  fi
  read -p "Install GUI Apps (krusader, ) (y/n)? " ok
  if [ "${ok}" == "y" ]; then
    sudo -S apt install -y krusader krename kget kompare mlocate
  fi
  echo "--------------------------------------------------"
  read -p "Done for the moment, reboot (y/n)? " ok
  if [ "${ok}" == "y" ]; then
    echo "Sanity reboot..."
    sudo reboot
  fi
  
else
  echo "--------------------------------------------------"
  echo "Done..."
fi
echo "--------------------------------------------------"
