#!/bin/bash
# --------------------------------------------------------------------------------
# Fedora 44 setup script
# Note: Requires running on Fedora 44 or newer
# --------------------------------------------------------------------------------

echo "----------------------------------------------------------------------------------------------------"
# Detect distribution
if [[ -f /etc/fedora-release ]]; then
  fedora_ver=$(cat /etc/fedora-release | grep -oP '\d+' | head -1)
  echo "Fedora version: ${fedora_ver}"
else
  echo "ERROR: Not running on Fedora"
  exit 1
fi

if [[ ${fedora_ver} -lt 44 ]]; then
  echo "WARNING: Script designed for Fedora 44+, current version: ${fedora_ver}"
fi

# Check for WSL
if [[ $(grep -i Microsoft /proc/version) ]]; then
  WSL=1
  browser="/mnt/c/\"Program Files (x86)\"/Microsoft/Edge/Application/msedge.exe"
  echo "Under WSL..."
else
  WSL=0
  browser="xdg-open"
fi

echo "The following script will do a custom install of the required apps for R&D... (manual mode)"

# Fedora update
echo "--------------------------------------------------"
echo "update/upgrade/remove"
sudo dnf update -y && sudo dnf clean all

# For USB/UART serial access (dialout group exists in Fedora)
echo "--------------------------------------------------"
echo "${USER}->dialout"
sudo usermod -a -G dialout ${USER}

# R&D dirs
echo "--------------------------------------------------"
echo "Creating common dirs..."
cd ~; mkdir -p dev tools repos tmp

# Required apps (Fedora package names differ from Ubuntu)
echo "--------------------------------------------------"
echo "dnf required tools..."
sudo dnf install -y \
  gcc \
  gcc-c++ \
  git \
  graphviz \
  screen \
  tmux \
  tree \
  vim \
  openssh-server \
  net-tools \
  keychain \
  which

if [ ${WSL} -eq 0 ]; then
  # GUI tools on Fedora
  sudo dnf install -y gtkwave
else
  echo "WSL mode - skipping GUI packages"
fi

echo "--------------------------------------------------"
read -p "GNOME setup (y/n)? " ok
if [ "${ok}" == "y" ]; then
  if [ ${WSL} -eq 0 ]; then
    sudo dnf install -y gnome-shell-extensions chrome-gnome-shell gnome-shell-extension-manager
    # Fedora uses flatpak by default, ensure it's installed
    sudo dnf install -y flatpak
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true
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
  # Fedora default is pull.rebase, set explicitly
  git config --global pull.rebase true
fi

# SSH key for GitHub
echo "--------------------------------------------------"
ssh_key="${HOME}/.ssh/id_ed25519"
if [ ! -f "${ssh_key}" ]; then
  echo "Creating GitHub ssh-key"
  ssh-keygen -t ed25519 -C "${email}"
  eval $(ssh-agent -s)
  chmod 600 ~/.ssh/id_ed25519
  ssh-add ~/.ssh/id_ed25519
  echo "Copy/paste (and create key at GitHub) ->"
  cat ~/.ssh/id_ed25519.pub
  ${browser} "https://github.com/settings/keys" >/dev/null 2>&1

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

# DevSetup repo clone and setup
echo "--------------------------------------------------"
read -p "Clone and update .bashrc with <devsetup> (y/n)? " ok
if [ "${ok}" == "y" ]; then
  if [ ! -d "${HOME}/dev/devsetup" ]; then
    echo "Cloning GitHub dramoz/devsetup.git and set .bash*"
    cd ~/dev
    git clone git@github.com:dramoz/devsetup.git
  fi

  echo "--------------------------------------------------"
  cd ~/dev/devsetup; git pull; cd ~

  # Copy distro-specific bashrc if exists, otherwise copy base bashrc
  BASHRC_SRC="${HOME}/dev/devsetup/scripts/.bashrc_fedora"
  if [[ -f "${BASHRC_SRC}" ]]; then
    echo "Copying ${BASHRC_SRC} to ~/.bashrc"
    cp ${BASHRC_SRC} ~/.bashrc
  else
    echo "Copying .bashrc (base) to ~/.bashrc"
    cp ~/dev/devsetup/scripts/.bashrc ~/.bashrc
  fi

  # Copy distro-specific aliases if exists, otherwise copy base aliases with Fedora additions
  BASHALIASES_SRC="${HOME}/dev/devsetup/scripts/.bash_aliases_fedora"
  if [[ -f "${BASHALIASES_SRC}" ]]; then
    echo "Copying ${BASHALIASES_SRC} to ~/.bash_aliases"
    cp ${BASHALIASES_SRC} ~/.bash_aliases
  else
    # Copy base aliases and add Fedora-specific section at the end
    cp ~/dev/devsetup/scripts/.bash_aliases ~/.bash_aliases
    echo "" >> ~/.bash_aliases
    echo "# Fedora-specific aliases" >> ~/.bash_aliases
    alias_fedora="alias apt_update_all='sudo dnf update -y && sudo dnf upgrade -y'"
    echo $alias_fedora >> ~/.bash_aliases
  fi

  if [ ! -f "${HOME}/.bashrc_local" ]; then
    echo "devsetup: .bashrc can load local configurations from ~/.bashrc_local"
    cp ~/dev/devsetup/scripts/.bashrc_local ~/.bashrc_local
  fi

  source ~/.bashrc
fi

echo "----------------------------------------------------------------------------------------------------"

# VS Code installation (per https://code.visualstudio.com/docs/setup/linux)
echo "--------------------------------------------------"
read -p "Install VS code (y/n)? " ok
if [ "${ok}" == "y" ]; then
  echo "Installing VS Code on Fedora"

  # Add Microsoft repo and install via dnf (Official method for RHEL/Fedora)
  sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
  echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ntype=rpm-md\ngpgcheck=1" | sudo tee /etc/yum.repos.d/vscode.repo
  sudo dnf install -y code

  echo "--------------------------------------------------"
  read -p "Install VS code extensions + user settings (select 'n' if using code sync) (y/n)? " ok
  if [ "${ok}" == "y" ]; then
    echo "Installing VS Code extensions"

    # Check if code command is available
    if ! command -v code &> /dev/null; then
      echo "WARNING: 'code' command not found. VS Code may need restart or PATH reload."
    fi

    echo "Installing UI workspace extensions"
    while IFS= read -r line; do
      code --install-extension ${line} 2>/dev/null || true
    done < ${HOME}/dev/devsetup/scripts/assets/vscode/ui_extensions.ext

    while IFS= read -r line; do
      code --install-extension ${line} 2>/dev/null || true
    done < ${HOME}/dev/devsetup/scripts/assets/vscode/workspace_extensions.ext

    echo "Restoring user settings"
    # Fedora uses same config path as Ubuntu
    mkdir -p ${HOME}/.config/Code/User/
    cp ${HOME}/dev/devsetup/scripts/assets/vscode/*.json ${HOME}/.config/Code/User/ 2>/dev/null || true
  fi
fi

if [ ${WSL} -eq 0 ]; then
  echo "--------------------------------------------------"
  read -p "Install GNOME desktop links (y/n)? " ok
  if [ "${ok}" == "y" ]; then
    echo "Installing desktop links"
    cp ~/dev/devsetup/scripts/assets/Desktop/* ~/Desktop/ 2>/dev/null || true
  fi

  echo "--------------------------------------------------"
  read -p "Install Brave Browser (y/n)? " ok
  if [ "${ok}" == "y" ]; then
    echo "Installing Brave browser"
    sudo dnf install -y dnf-plugins-core
    sudo rpm -Uvh https://brave-browser-rpm-release.s3.brave.com/brave-core.asc 2>/dev/null || true
    sudo sh -c 'echo -e "[brave-browser]\nname=Brave Browser\nbaseurl=https://brave-browser-rpm-release.s3.brave.com/x86_64/\nenabled=1\ngpgcheck=1\ngpgkey=https://brave-browser-rpm-release.s3.brave.com/brave-core.asc" > /etc/yum.repos.d/brave-browser.repo'
    sudo dnf install -y brave-browser
  fi

  echo "--------------------------------------------------"
  read -p "Install GUI Apps (krusader, ) (y/n)? " ok
  if [ "${ok}" == "y" ]; then
    # krusader not in default Fedora repos, need to enable RPM Fusion
    echo "Note: Some GUI apps may require RPM Fusion repository"
    sudo dnf install -y krename kget kompare mlocate
  fi

  echo "--------------------------------------------------"
fi

echo "----------------------------------------------------------------------------------------------------"
read -p "Done for the moment, reboot (y/n)? " ok
if [ "${ok}" == "y" ]; then
  echo "Sanity reboot..."
  sudo reboot
else
  echo "Done. Please restart your session for group changes to take effect."
fi

echo "--------------------------------------------------"
