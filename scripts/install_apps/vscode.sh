#!/bin/bash
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

echo "----------------------------------------------------------------------------------------------------"
read -p "Install Visual Studio Code? (y/n)" ok
if [ "${ok}" == "y" ]; then
  read -p "Try to remove/purge previous VS code+extensions+settings (y/n)? " ok
  if [ "${ok}" == "y" ];  then
    echo "Removing old just in case..."
    sudo -S apt purge code && sudo apt autoremove
    sudo -S snap remove code
    rm -fr ~/.vscode/
    rm -fr ~/.config/Code
  fi
  
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
  read -p "Install VS code extensions + user settings (y/n)? " ok
  
  if [ "${ok}" == "y" ];  then
    echo "Installing VS Code extensions"
    while IFS= read -r line; do
      code --install-extension ${line}
    done < ${HOME}/dev/devsetup/scripts/assets/vscode/all_extensions.ext
    
    cp ${HOME}/dev/devsetup/scripts/assets/vscode/*.json ${HOME}/.config/Code/User/
  fi
fi
