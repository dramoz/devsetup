#!/bin/bash
# --------------------------------------------------------------------------------
VENV_TGT="hdl"
# --------------------------------------------------------------------------------
echo "---------------------------------------------------------"
echo "-> Please make sure that ./ubuntu_setup.sh AND riscv.sh were run before!!"

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
sudo -S apt update -y && sudo -S apt upgrade -y && sudo -S apt dist-upgrade -y && sudo -S apt autoremove -y

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

echo "----------------------------------------------------------------------------------------------------"
echo "Python update..."
pip install --upgrade pip setuptools virtualenv
pip install -r ~/dev/devsetup/virtualenv/dev_requirements.txt
#pip install -r ~/dev/devsetup/virtualenv/hdl_requirements.txt
#pip install -r ~/dev/devsetup/virtualenv/pytest_requirements.txt

echo "----------------------------------------------------------------------------------------------------"
echo "Installing SBT/Scala"
sudo -S apt install -y openjdk-8-jdk
sudo -S apt install -y scala
echo "deb https://repo.scala-sbt.org/scalasbt/debian all main" | sudo -S tee /etc/apt/sources.list.d/sbt.list
echo "deb https://repo.scala-sbt.org/scalasbt/debian /" | sudo -S tee /etc/apt/sources.list.d/sbt_old.list
curl -sL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x2EE0EA64E40A89B84B2DF73499E82A75642AC823" | sudo -S apt-key add
sudo -S apt update -y
sudo -S apt install -y sbt

echo "----------------------------------------------------------------------------------------------------"
read -p "Test SpinalHDL (https://spinalhdl.github.io/SpinalDoc-RTD/master/index.html) (y/n)? " ok
if [ "${ok}" == "y" ]; then
  echo ".................................................."
  # Check if SpinalTemplateSbt repository exists
  cd ${HOME}/repos
  if [ ! -d "SpinalTemplateSbt" ]; then
    git clone https://github.com/SpinalHDL/SpinalTemplateSbt.git SpinalTemplateSbt
  fi
  cd SpinalTemplateSbt
  echo "select mylib.MyTopLevelVhdl or mylib.MyTopLevelVerilog in the menu..."
  sbt run
fi

echo "----------------------------------------------------------------------------------------------------"
# Check if VexRiscv repository exists
echo "Cloning VexRiscv..."
cd ${HOME}/repos
if [ ! -d "VexRiscv" ]; then
  git clone git@github.com:SpinalHDL/VexRiscv.git
fi
cd VexRiscv
git pull
read -p "Test VexRiscv by generating GenFull (y/n)? " ok
if [ "${ok}" == "y" ]; then
 sbt "runMain vexriscv.demo.GenFull"
fi

echo "----------------------------------------------------------------------------------------------------"
echo "Done"
echo "----------------------------------------------------------------------------------------------------"
