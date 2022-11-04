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

echo "--------------------------------------------------"
# Ubuntu update
echo "update/upgrade/remove"
sudo -S apt update -y && sudo -S apt upgrade -y && sudo apt dist-upgrade -y && sudo apt autoremove -y

echo "--------------------------------------------------"
# R&D dirs
echo "Creating common dirs..."
cd ~; mkdir -p dev tools repos tmp

echo "----------------------------------------------------------------------------------------------------"
echo "VS Code Server/Remote extensions (https://code.visualstudio.com/api/advanced-topics/remote-extensions#architecture-and-extension-types)"
echo "- UI Extensions -> run on host"
echo "- Workspace Extensions -> run on remote"
echo "--------------------------------------------------------"
echo "!!! Run this script inside VS Code terminal after"
echo "!!! establishing the remote connection (ssh usr@remote)"
echo "--------------------------------------------------------"
read -p "Install Visual Studio Code (Server) Extensions? (y/n)" ok
if [ "${ok}" == "y" ]; then
  echo "Installing VS Code (Server) Extensions..."
  if [ "${ok}" == "y" ];  then
    echo "Installing VS Code extensions"
    while IFS= read -r line; do
      code --install-extension ${line}
    done < ${HOME}/dev/devsetup/scripts/assets/vscode/server_extensions.ext
  fi
fi

echo "----------------------------------------------------------------------------------------------------"
echo "Done! Pleaser reload VS code!!!"
echo "----------------------------------------------------------------------------------------------------"
