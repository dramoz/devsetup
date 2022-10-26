#!/bin/bash
echo "---------------------------------------------------------"
echo "Install Gnome extensions and restore gnome configuration"
echo "-> Please make sure that ./ubuntu_setup.sh was run before!!"
read -p "Continue (y/n)? " ok

if [ "${ok}" == "n" ]; then
  exit 1
fi

ubuntu_release=$(lsb_release -r)
ubuntu_ver=$(cut -f2 <<< "$ubuntu_release")
echo "$ubuntu_ver"

# https://www.addictivetips.com/ubuntu-linux-tips/back-up-the-gnome-shell-desktop-settings-linux/
dconf_gnome_bk=${HOME}/dev/devsetup/scripts/assets/gnome-backup

echo "--------------------------------------------------"
echo "Installing gnome-shell-extensions..."
echo "Dash to Panel (https://extensions.gnome.org/extension/1160/dash-to-panel/)"
echo "Resource Monitor (https://extensions.gnome.org/extension/1634/resource-monitor/)"
echo "Applications Menu (https://extensions.gnome.org//extension/6/applications-menu/)"
echo "Removable Drive Menu (https://extensions.gnome.org/extension/7/removable-drive-menu/)"
echo "Workspace Indicator (https://extensions.gnome.org/extension/21/workspace-indicator/)"
echo "Places Status Indicator (https://extensions.gnome.org/extension/8/places-status-indicator/)"


echo "--------------------------------------------------"
echo "Downloading gnome-extension-installer..."
wget -O gnome-shell-extension-installer "https://github.com/brunelli/gnome-shell-extension-installer/raw/master/gnome-shell-extension-installer"
chmod +x gnome-shell-extension-installer
sudo -S mv gnome-shell-extension-installer /usr/bin/

if [ "`echo "${ubuntu_ver} >= 22.04" | bc`" -eq 1 ]; then
  echo "--------------------------------------------------"
  echo "Installing  Dash2Pnl, Resources.Mon"
  gnome-shell-extension-installer 1160 1634 --yes
  
  echo "Enabling extensions (Apps.Menu, Places, Rm.Drv, Workspace)"
  gnome-extensions enable apps-menu@gnome-shell-extensions.gcampax.github.com
  gnome-extensions enable places-menu@gnome-shell-extensions.gcampax.github.com
  gnome-extensions enable drive-menu@gnome-shell-extensions.gcampax.github.com
  gnome-extensions enable workspace-indicator@gnome-shell-extensions.gcampax.github.com
  
else
  #if [ "`echo "${ubuntu_ver} == 20.04" | bc`" -eq 1 ]; then
    echo "--------------------------------------------------"
    echo "Installing ExtensionManager, run as gnome_ext_mngr (reboot required first)"
    flatpak install -y flathub com.mattjakeman.ExtensionManager
    if ! grep -q "gnome_ext_mngr" "${HOME}/.bashrc_local"; then
      echo '# --------------------------------'  >> ~/.bashrc_local
      echo '# Ghnome Extension Manager (alias with flatpak)' >> ~/.bashrc_local
      echo 'alias gnome_ext_mngr="flatpak run com.mattjakeman.ExtensionManager"' >> ~/.bashrc_local
    fi
    
    echo "Installing: Dash2Pnl, Resources.Mon, Apps.Menu, Places, Rm.Drv, Workspace"
    gnome-shell-extension-installer 1160 1634 6 7 21 8 --yes
  #fi
fi

if [ -f "${dconf_gnome_bk}" ]; then
  read -p "Restore dconf.gnome preferences (y/n)? " ok
  if [ "${ok}" == "y" ]; then
    dconf load /org/gnome/ < ${dconf_gnome_bk}
  fi
else
  echo "${dconf_gnome_bk} file not found, skipping dconf restore"
fi

echo "--------------------------------------------------"
read -p "Done for the moment, reboot (y/n)? " ok
if [ "${ok}" == "y" ]; then
  sudo reboot
else
  echo "Please reboot at your convenience..."
fi

