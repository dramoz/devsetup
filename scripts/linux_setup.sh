#!/bin/bash
# --------------------------------------------------------------------------------
# Linux setup script (Ubuntu 24.04+ / Fedora 44+)
# Auto-detects distro via /etc/os-release and uses appropriate package manager
# --------------------------------------------------------------------------------

echo "----------------------------------------------------------------------------------------------------"

# Detect distribution
if [[ -f /etc/os-release ]]; then
  source /etc/os-release
  DISTRO_NAME="${NAME}"
  DISTRO_VER="${VERSION_ID}"
else
  ubuntu_release=$(lsb_release -r)
  ubuntu_ver=$(cut -f2 <<< "$ubuntu_release")
  echo "$ubuntu_ver"
fi

echo "${DISTRO_NAME:-Linux}: ${DISTRO_VER:-unknown}"

# Check if running on Ubuntu/Fedora and set package manager
if [[ "${ID}" == "ubuntu" ]] || [[ "${ID_LIKE}" == *"ubuntu"* ]]; then
  PKG_MGR="apt"
  echo "Detected: Ubuntu-based system (using apt)"
elif [[ "${ID}" == "fedora" ]] || [[ "${ID_LIKE}" == *"fedora"* ]]; then
  PKG_MGR="dnf"
  echo "Detected: Fedora-based system (using dnf)"
else
  PKG_MGR="apt"
  echo "WARNING: Unknown distro, defaulting to apt"
fi

# Set browser based on environment
if [[ $(grep -i Microsoft /proc/version) ]]; then
  WSL=1
  browser="/mnt/c/\"Program Files (x86)\"/Microsoft/Edge/Application/msedge.exe"
  echo "Under WSL..."
else
  WSL=0
  browser="xdg-open"
fi

echo "The following script will do a custom install of the required apps for R&D... (manual mode)"

# Remove virtualenv and virtualenvwrapper (only if installed)
if [[ "${PKG_MGR}" == "apt" ]]; then
  echo "--------------------------------------------------"
  echo "Removing default Ubuntu virtualenv/virtualenvwrapper"
  sudo -S apt purge -y virtualenv virtualenvwrapper 2>/dev/null || true

  # Ubuntu update (Ubuntu 24.04 compatible)
  echo "--------------------------------------------------"
  echo "update/upgrade/remove"
  sudo -S apt update -y && sudo -S apt upgrade -y && sudo -S apt dist-upgrade -y && sudo -S apt autoremove -y
  sudo -S apt fix-broken -y 2>/dev/null || true
fi

if [[ "${PKG_MGR}" == "dnf" ]]; then
  echo "--------------------------------------------------"
  echo "Removing default Fedora virtualenv/virtualenvwrapper"
  sudo dnf remove -y python3-virtualenv python3-virtualenvwrapper 2>/dev/null || true

  # Fedora update
  echo "--------------------------------------------------"
  echo "update/upgrade/remove"
  sudo dnf update -y && sudo dnf clean all
fi

# For USB/UART serial access (dialout group exists in both Ubuntu and Fedora)
echo "--------------------------------------------------"
echo "${USER}->dialout"
if [[ "${PKG_MGR}" == "apt" ]]; then
  sudo -S adduser $USER dialout
fi
if [[ "${PKG_MGR}" == "dnf" ]]; then
  sudo usermod -a -G dialout $USER
fi

# R&D dirs
echo "--------------------------------------------------"
echo "Creating common dirs..."
cd ~; mkdir -p dev tools repos tmp

# Required apps (distro-specific package manager)
echo "--------------------------------------------------"

if [[ "${PKG_MGR}" == "apt" ]]; then
  echo "apt required tools..."
  # Ubuntu 24.04: Install base tools
  sudo -S apt install -y build-essential git graphviz screen tmux tree vim openssh-server net-tools keychain which
fi

if [[ "${PKG_MGR}" == "dnf" ]]; then
  echo "dnf required tools..."
  # Fedora: equivalent packages
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
fi

# GUI tools (WSL check for both distros)
if [ ${WSL} -eq 0 ]; then
  if [[ "${PKG_MGR}" == "apt" ]]; then
    sudo -S apt install -y gtkwave libcanberra-gtk-module libcanberra-gtk3-module libcanberra-gtk-module:i386
  fi
  if [[ "${PKG_MGR}" == "dnf" ]]; then
    # Fedora uses different library naming
    sudo dnf install -y gtkwave libcanberra
  fi
else
  echo "WSL mode - skipping GUI packages"
fi

echo "--------------------------------------------------"
read -p "GNOME setup (y/n)? " ok
if [ "${ok}" == "y" ]; then
  if [ ${WSL} -eq 0 ]; then
    if [[ "${PKG_MGR}" == "apt" ]]; then
      sudo -S apt install -y gnome-shell-extensions chrome-gnome-shell gnome-shell-extension-manager
    fi
    if [[ "${PKG_MGR}" == "dnf" ]]; then
      # Fedora: GNOME extensions available via dnf
      sudo dnf install -y gnome-shell-extensions chrome-gnome-shell gnome-shell-extension-manager
    fi

    # Flatpak is standard on Fedora 44+, needs installation on older Ubuntu
    if [[ "${ID}" == "fedora" ]] || [[ "${PKG_MGR}" == "dnf" ]]; then
      sudo dnf install -y flatpak
      flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true
    else
      # Ubuntu: check version for flatpak requirement
      ubuntu_release=$(lsb_release -r)
      ubuntu_ver=$(cut -f2 <<< "$ubuntu_release")
      if [ "`echo "${ubuntu_ver} < 22.04" | bc`" -eq 1 ]; then
        sudo apt install flatpak
        flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
      fi
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
  # Fedora default is rebase, Ubuntu uses merge - set explicitly based on distro
  if [[ "${PKG_MGR}" == "dnf" ]]; then
    git config --global pull.rebase true
  else
    git config --global pull.rebase false
  fi
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
  BASHRC_SRC="${HOME}/dev/devsetup/scripts/.bashrc_${ID}"
  if [[ -f "${BASHRC_SRC}" ]]; then
    echo "Copying ${BASHRC_SRC} to ~/.bashrc"
    cp ${BASHRC_SRC} ~/.bashrc
  else
    echo "Copying .bashrc (base) to ~/.bashrc"
    cp ~/dev/devsetup/scripts/.bashrc ~/.bashrc
  fi

  # Copy distro-specific aliases if exists, otherwise copy base aliases
  BASHALIASES_SRC="${HOME}/dev/devsetup/scripts/.bash_aliases_${ID}"
  if [[ -f "${BASHALIASES_SRC}" ]]; then
    echo "Copying ${BASHALIASES_SRC} to ~/.bash_aliases"
    cp ${BASHALIASES_SRC} ~/.bash_aliases
  else
    # Fallback: copy base aliases and add distro-specific section at the end
    cp ~/dev/devsetup/scripts/.bash_aliases ~/.bash_aliases
    echo "" >> ~/.bash_aliases
    if [[ "${PKG_MGR}" == "dnf" ]]; then
      echo "# Fedora-specific aliases" >> ~/.bash_aliases
      alias_distro='alias apt_update_all="sudo dnf update -y && sudo dnf upgrade -y"'
      echo $alias_distro >> ~/.bash_aliases
    else
      echo "# Ubuntu-specific aliases" >> ~/.bash_aliases
      alias_distro='alias apt_update_all="sudo apt update -y && sudo apt upgrade -y && sudo apt dist-upgrade -y && sudo apt autoremove -y"'
      echo $alias_distro >> ~/.bash_aliases
    fi
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
  echo "Installing VS Code"

  if [[ "${PKG_MGR}" == "apt" ]]; then
    # Ubuntu: Use Microsoft GPG key and apt repository (Ubuntu 24.04 compatible)
    echo "Configuring VS Code repository for Ubuntu..."
    sudo mkdir -p /usr/share/keyrings
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /usr/share/keyrings/vscode.gpg
    echo "Types: deb
URIs: https://packages.microsoft.com/repos/code
Suites: stable
Components: main
Architectures: amd64,arm64,armhf
Signed-By: /usr/share/keyrings/vscode.gpg" | sudo tee /etc/apt/sources.list.d/vscode.sources
    sudo apt update -y
    sudo apt install -y code
  fi

  if [[ "${PKG_MGR}" == "dnf" ]]; then
    # Fedora: Add Microsoft repo and install via dnf
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
    echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ntype=rpm-md\ngpgcheck=1" | sudo tee /etc/yum.repos.d/vscode.repo
    sudo dnf install -y code
  fi

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
  read -p "Install Brave Browser (chromium alternative) (y/n)? " ok
  if [ "${ok}" == "y" ]; then
    if [[ "${PKG_MGR}" == "apt" ]]; then
      # Ubuntu: Add repository via apt (Ubuntu 24.04 compatible)
      sudo -S apt -y install apt-transport-https curl
      sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
      echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg arch=amd64] https://brave-browser-apt-release.s3.brave.com/ stable main"|sudo tee /etc/apt/sources.list.d/brave-browser-release.list
      sudo -S apt update -y
      sudo -S apt install -y brave-browser
    fi

    if [[ "${PKG_MGR}" == "dnf" ]]; then
      # Fedora: Add repository via dnf
      sudo dnf install -y dnf-plugins-core
      sudo rpm -Uvh https://brave-browser-rpm-release.s3.brave.com/brave-core.asc 2>/dev/null || true
      sudo sh -c 'echo -e "[brave-browser]\nname=Brave Browser\nbaseurl=https://brave-browser-rpm-release.s3.brave.com/x86_64/\nenabled=1\ngpgcheck=1\ngpgkey=https://brave-browser-rpm-release.s3.brave.com/brave-core.asc" > /etc/yum.repos.d/brave-browser.repo'
      sudo dnf install -y brave-browser
    fi
  fi

  echo "--------------------------------------------------"
  read -p "Install GUI Apps (krusader, ) (y/n)? " ok
  if [ "${ok}" == "y" ]; then
    if [[ "${PKG_MGR}" == "apt" ]]; then
      sudo -S apt install -y krusader krename kget kompare mlocate
    fi
    if [[ "${PKG_MGR}" == "dnf" ]]; then
      # Fedora: Install available GUI apps (some may require RPM Fusion)
      echo "Note: Some GUI apps may require RPM Fusion repository"
      sudo dnf install -y krename kget kompare mlocate
    fi
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

# Final summary
echo ""
echo "Setup complete for ${DISTRO_NAME:-Unknown} ${DISTRO_VER:-unknown}"
if [[ "${PKG_MGR}" == "dnf" ]]; then
  echo "Note: Restart your session for group changes to take effect"
else
  echo "Note: Restart your session for group changes to take effect"
fi
echo "--------------------------------------------------"
