
#!/bin/bash
# --------------------------------------------------------------------------------
# https://kivy.org/doc/stable/gettingstarted/installation.html

echo "---------------------------------------------------------"
echo "-> Please make sure that ./ubuntu_setup.sh was run before!!"
read -p "Continue (y/n)? " ok
if [ "${ok}" != "y" ]; then
  exit 1
fi
echo "--------------------------------------------------"

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
# VirtualEnv
source $HOME/.local/bin/virtualenvwrapper.sh
echo "--------------------------------------------------"
python=${VIRTUAL_ENV}
if [ -z ${python} ]; then
  read -p "No virtualenv active detected, create/use virtualenv:gui (y/n)? " ok
  if [ "${ok}" == "y" ]; then
    if [ ! -d "${HOME}/.virtualenvs/gui/" ]; then
      echo "virtualenv:gui not found, creating..."
      mkvirtualenv gui
      source .virtualenvs/gui/bin/activate
    else
      source .virtualenvs/gui/bin/activate
    fi
  fi
fi

echo "----------------------------------------------------------------------------------------------------"
echo "Installing python requirements"
pip install --upgrade pip setuptools virtualenv
pip install -r ~/dev/devsetup/virtualenv/dev_requirements.txt
pip install -r ~/dev/devsetup/virtualenv/pytest_requirements.txt

echo "----------------------------------------------------------------------------------------------------"
read -p "Install Kivy + VS code extensions (https://kivy.org/) (y/n)? " ok
if [ "${ok}" == "y" ]; then
  echo ".................................................."
  echo "Installing on python virtualenv: ${VIRTUAL_ENV}"
  echo ".................................................."
  pip install "kivy[base]" kivy_examples
  code --install-extension BattleBas.kivy-vscode
  code --install-extension watchakorn-18k.kivy-snippets
fi

echo "----------------------------------------------------------------------------------------------------"
read -p "Install Qt (python + tools) (https://kivy.org/) (y/n)? " ok
if [ "${ok}" == "y" ]; then
  echo ".................................................."
  echo "Installing on python virtualenv: ${VIRTUAL_ENV}"
  echo ".................................................."
  #pip install pyqt5 pyqt5-tools
  pip install pyside6
  sudo -S apt install -y libx11-xcb-dev libxcb-xinerama0 libgl1-mesa-dev qt6-tools-dev-tools qt6-base-dev
  code --install-extension seanwu.vscode-qt-for-python
  code --install-extension tonka3000.qtvsctools
fi

echo "----------------------------------------------------------------------------------------------------"
read -p "Install PySimpleGUI (https://www.pysimplegui.org/en/latest/) (y/n)? " ok
if [ "${ok}" == "y" ]; then
  echo ".................................................."
  echo "Installing on python virtualenv: ${VIRTUAL_ENV}"
  echo ".................................................."
  #sudo -S apt install -y libx11-xcb-dev libxcb-xinerama0 libgl1-mesa-dev qt6-tools-dev-tools qt6-base-dev
  pip install pysimplegui
fi

echo "----------------------------------------------------------------------------------------------------"
echo "Done"
echo "----------------------------------------------------------------------------------------------------"
