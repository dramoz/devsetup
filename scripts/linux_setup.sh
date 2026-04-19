#!/bin/bash
# --------------------------------------------------------------------------------
# Linux setup script — Ubuntu 24.04+ / Fedora 43+
# Auto-detects distro via /etc/os-release. Idempotent where reasonable.
# --------------------------------------------------------------------------------
set -uo pipefail

L1='======================================================================'
L2='----------------------------------------------------------------------'

# --------------------------------------------------------------------------------
# Distro / WSL detection
# --------------------------------------------------------------------------------
if [[ ! -f /etc/os-release ]]; then
    echo "ERROR: /etc/os-release missing — unsupported system" >&2
    exit 1
fi
# shellcheck disable=SC1091
source /etc/os-release

DISTRO_NAME="${NAME:-Linux}"
DISTRO_VER="${VERSION_ID:-unknown}"

if [[ "${ID:-}" == "ubuntu" ]] || [[ "${ID_LIKE:-}" == *"ubuntu"* ]] || [[ "${ID_LIKE:-}" == *"debian"* ]]; then
    PKG_MGR="apt"
elif [[ "${ID:-}" == "fedora" ]] || [[ "${ID_LIKE:-}" == *"fedora"* ]] || [[ "${ID_LIKE:-}" == *"rhel"* ]]; then
    PKG_MGR="dnf"
else
    echo "ERROR: unsupported distro id='${ID:-}'  id_like='${ID_LIKE:-}'" >&2
    exit 1
fi

if grep -qi microsoft /proc/version 2>/dev/null; then
    WSL=1
    BROWSER='/mnt/c/Program Files (x86)/Microsoft/Edge/Application/msedge.exe'
else
    WSL=0
    BROWSER='xdg-open'
fi

DEVSETUP_DIR="${HOME}/dev/devsetup"
SCRIPTS_DIR="${DEVSETUP_DIR}/scripts"

echo "${L1}"
echo "Devsetup: ${DISTRO_NAME} ${DISTRO_VER}  (pkg=${PKG_MGR}, wsl=${WSL})"
echo "${L1}"

# --------------------------------------------------------------------------------
# Helpers
# --------------------------------------------------------------------------------
ask() {
    local prompt="$1" reply
    read -rp "${prompt} (y/n)? " reply
    [[ "${reply}" == "y" ]]
}

pkg_install() {
    if [[ "${PKG_MGR}" == "apt" ]]; then
        sudo apt install -y "$@"
    else
        sudo dnf install -y "$@"
    fi
}

pkg_update() {
    echo "${L2}"
    echo "System update"
    if [[ "${PKG_MGR}" == "apt" ]]; then
        sudo apt update -y \
            && sudo apt upgrade -y \
            && sudo apt dist-upgrade -y \
            && sudo apt autoremove -y
        sudo apt install --fix-broken -y || true
    else
        sudo dnf update -y && sudo dnf clean all
    fi
}

# --------------------------------------------------------------------------------
# System update
# --------------------------------------------------------------------------------
pkg_update

# --------------------------------------------------------------------------------
# User to dialout (USB / UART)
# --------------------------------------------------------------------------------
echo "${L2}"
echo "Adding ${USER} to dialout group"
sudo usermod -a -G dialout "${USER}"

# --------------------------------------------------------------------------------
# Common dirs
# --------------------------------------------------------------------------------
echo "${L2}"
echo "Creating ~/dev ~/tools ~/repos ~/tmp"
mkdir -p "${HOME}/dev" "${HOME}/tools" "${HOME}/repos" "${HOME}/tmp"

# --------------------------------------------------------------------------------
# Required packages
# Note: virtualenv + virtualenvwrapper come from the distro package; PEP 668
# blocks `pip install --user` on both Fedora 43 and Ubuntu 24.04, so the old
# pip-based setup no longer works.
# --------------------------------------------------------------------------------
echo "${L2}"
echo "Installing base tools"
if [[ "${PKG_MGR}" == "apt" ]]; then
    pkg_install \
        build-essential git graphviz screen tmux tree vim openssh-server \
        net-tools keychain curl ca-certificates \
        python3 python3-virtualenv virtualenvwrapper
else
    pkg_install \
        gcc gcc-c++ make git graphviz screen tmux tree vim openssh-server \
        net-tools keychain curl ca-certificates which \
        python3 python3-virtualenv python3-virtualenvwrapper
fi

# GUI tools (skip on WSL)
if (( WSL == 0 )); then
    echo "${L2}"
    echo "Installing GUI tools (gtkwave)"
    if [[ "${PKG_MGR}" == "apt" ]]; then
        pkg_install gtkwave libcanberra-gtk3-module
    else
        pkg_install gtkwave libcanberra
    fi
fi

# --------------------------------------------------------------------------------
# GNOME extras (chrome-gnome-shell was removed on Fedora 41+ / Ubuntu 24.04+;
# replaced by gnome-browser-connector)
# --------------------------------------------------------------------------------
if (( WSL == 0 )) && ask "Install GNOME shell extension manager"; then
    if [[ "${PKG_MGR}" == "apt" ]]; then
        pkg_install gnome-shell-extensions gnome-shell-extension-manager gnome-browser-connector
    else
        pkg_install gnome-extensions-app gnome-browser-connector
    fi

    pkg_install flatpak
    flatpak remote-add --if-not-exists --user flathub \
        https://flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true
fi

# --------------------------------------------------------------------------------
# Git credentials & SSH key
# --------------------------------------------------------------------------------
EMAIL=""
if ask "Setup git credentials"; then
    while true; do
        read -rp 'Name LastName: ' full_name
        read -rp 'github email:  ' EMAIL
        echo "  ${full_name} <${EMAIL}>"
        ask "OK" && break
    done
    git config --global user.email "${EMAIL}"
    git config --global user.name  "${full_name}"
    git config --global credential.helper 'cache --timeout 30000'
    if [[ "${PKG_MGR}" == "dnf" ]]; then
        git config --global pull.rebase true
    else
        git config --global pull.rebase false
    fi
fi

SSH_KEY="${HOME}/.ssh/id_ed25519"
if [[ ! -f "${SSH_KEY}" ]]; then
    if ask "Generate ssh key for GitHub"; then
        ssh-keygen -t ed25519 -C "${EMAIL:-${USER}@$(hostname)}" -f "${SSH_KEY}"
        chmod 600 "${SSH_KEY}"
        eval "$(ssh-agent -s)"
        ssh-add "${SSH_KEY}"
        echo "Public key — paste into https://github.com/settings/keys :"
        cat "${SSH_KEY}.pub"
        "${BROWSER}" 'https://github.com/settings/keys' >/dev/null 2>&1 || true
        read -rp "Press <enter> after adding the key to GitHub" _
    fi
fi

# --------------------------------------------------------------------------------
# Devsetup repo + bash configuration
#
# We do NOT overwrite ~/.bashrc anymore — that broke the shell on Fedora because
# the distro skeleton sources /etc/bashrc (which loads /etc/profile.d/*.sh).
# Instead: install ~/.bashrc_user (our prompt + helpers + virtualenvwrapper)
# and append exactly one guarded source line to the distro's stock ~/.bashrc.
# --------------------------------------------------------------------------------
if ask "Clone devsetup and install bash configuration"; then
    if [[ ! -d "${DEVSETUP_DIR}" ]]; then
        echo "Cloning devsetup..."
        mkdir -p "${HOME}/dev"
        git clone git@github.com:dramoz/devsetup.git "${DEVSETUP_DIR}"
    else
        ( cd "${DEVSETUP_DIR}" && git pull ) || true
    fi

    if [[ ! -f "${HOME}/.bashrc_user" ]]; then
        echo "Installing ~/.bashrc_user"
        cp "${SCRIPTS_DIR}/.bashrc_user" "${HOME}/.bashrc_user"
    else
        echo "~/.bashrc_user already exists — leaving it; update manually if needed"
    fi

    if [[ ! -f "${HOME}/.bash_aliases" ]]; then
        echo "Installing ~/.bash_aliases"
        cp "${SCRIPTS_DIR}/.bash_aliases" "${HOME}/.bash_aliases"
    else
        echo "~/.bash_aliases already exists — leaving it; update manually if needed"
    fi

    if [[ ! -f "${HOME}/.bashrc_local" ]]; then
        echo "Installing ~/.bashrc_local from example"
        cp "${SCRIPTS_DIR}/.bashrc_local_example" "${HOME}/.bashrc_local"
    fi

    # Idempotent: add the source line only once
    if ! grep -qF '.bashrc_user' "${HOME}/.bashrc" 2>/dev/null; then
        echo "Appending devsetup source line to ~/.bashrc"
        {
            echo ''
            echo '# devsetup user customizations (prompt, aliases, virtualenvwrapper)'
            echo '[ -f "${HOME}/.bashrc_user" ] && . "${HOME}/.bashrc_user"'
        } >> "${HOME}/.bashrc"
    else
        echo "~/.bashrc already sources .bashrc_user — skipping"
    fi
fi

# --------------------------------------------------------------------------------
# VS Code
# --------------------------------------------------------------------------------
if ask "Install VS Code"; then
    if [[ "${PKG_MGR}" == "apt" ]]; then
        sudo install -d -m 0755 /usr/share/keyrings
        curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
            | sudo gpg --dearmor -o /usr/share/keyrings/vscode.gpg
        sudo tee /etc/apt/sources.list.d/vscode.sources >/dev/null <<'EOF'
Types: deb
URIs: https://packages.microsoft.com/repos/code
Suites: stable
Components: main
Architectures: amd64,arm64,armhf
Signed-By: /usr/share/keyrings/vscode.gpg
EOF
        sudo apt update -y
        pkg_install code
    else
        sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
        sudo tee /etc/yum.repos.d/vscode.repo >/dev/null <<'EOF'
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
type=rpm-md
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF
        pkg_install code
    fi

    if ask "Install VS Code extensions + user settings (skip if using Settings Sync)"; then
        if ! command -v code >/dev/null 2>&1; then
            echo "WARNING: 'code' not on PATH — open a new shell and re-run extension install"
        else
            while IFS= read -r ext; do
                [[ -n "${ext}" ]] && code --install-extension "${ext}" 2>/dev/null || true
            done < "${SCRIPTS_DIR}/assets/vscode/ui_extensions.ext"
            while IFS= read -r ext; do
                [[ -n "${ext}" ]] && code --install-extension "${ext}" 2>/dev/null || true
            done < "${SCRIPTS_DIR}/assets/vscode/workspace_extensions.ext"
            mkdir -p "${HOME}/.config/Code/User/"
            cp "${SCRIPTS_DIR}/assets/vscode/"*.json "${HOME}/.config/Code/User/" 2>/dev/null || true
        fi
    fi
fi

# --------------------------------------------------------------------------------
# Optional GUI extras (Linux only)
# --------------------------------------------------------------------------------
if (( WSL == 0 )); then
    if ask "Install GNOME desktop launchers"; then
        cp "${SCRIPTS_DIR}/assets/Desktop/"* "${HOME}/Desktop/" 2>/dev/null || true
    fi

    if ask "Install Brave browser"; then
        if [[ "${PKG_MGR}" == "apt" ]]; then
            pkg_install apt-transport-https curl
            sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg \
                https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
            echo 'deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg arch=amd64] https://brave-browser-apt-release.s3.brave.com/ stable main' \
                | sudo tee /etc/apt/sources.list.d/brave-browser-release.list >/dev/null
            sudo apt update -y
            pkg_install brave-browser
        else
            sudo dnf install -y dnf-plugins-core
            sudo dnf config-manager addrepo \
                --from-repofile=https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo 2>/dev/null \
                || sudo dnf config-manager --add-repo \
                    https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
            pkg_install brave-browser
        fi
    fi

    if ask "Install GUI utilities (krename, kget, kompare, plocate)"; then
        if [[ "${PKG_MGR}" == "apt" ]]; then
            pkg_install krusader krename kget kompare plocate
        else
            # Fedora 43: krusader needs RPM Fusion; the rest are in stock repos.
            pkg_install krename kget kompare plocate
            echo "Note: krusader requires RPM Fusion — skipped"
        fi
    fi

    if ask "Reboot now"; then
        sudo reboot
    fi
fi

echo "${L1}"
echo "Setup complete for ${DISTRO_NAME} ${DISTRO_VER}"
echo "Restart your shell (or open a new terminal) for group + bashrc changes to take effect."
echo "${L1}"
