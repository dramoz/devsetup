#!/bin/bash
# --------------------------------------------------------------------------------
VENV_TGT="dev"
ARM_VERSION="12.2.rel1"
HOST="x86_64"
ARM_TGT=("aarch64-none-linux-gnu" "aarch64-none-elf")
# --------------------------------------------------------------------------------
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
  else
    echo "This scripts only with virtualenv"
    exit 1
  fi
fi

echo "----------------------------------------------------------------------------------------------------"
echo "Python update..."
pip install --upgrade pip setuptools virtualenv
pip install -r ~/dev/devsetup/virtualenv/dev_requirements.txt
#pip install -r ~/dev/devsetup/virtualenv/hdl_requirements.txt
pip install -r ~/dev/devsetup/virtualenv/pytest_requirements.txt

echo "----------------------------------------------------------------------------------------------------"
read -p "Install ARM GNU Toolchain (https://developer.arm.com/Tools%20and%20Software/GNU%20Toolchain) (baremetal+linux) (y/n)? " ok

if [ "${ok}" == "y" ]; then
  echo ".................................................."
  cd ${HOME}/tmp
  TAR_EXT="tar.xz"
  for TGT in ${ARM_TGT[@]}; do
    ARM_TOOL_CHAIN="arm-gnu-toolchain-${ARM_VERSION}-${HOST}-${TGT}"
    ARM_PATH_TGT="arm-gnu-toolchain-${TGT}"
    if [ ! -d ${ARM_TOOL_CHAIN} ] && [ ! -f "${ARM_TOOL_CHAIN}.${TAR_EXT}" ]; then
      wget -O ${ARM_TOOL_CHAIN}.${TAR_EXT} https://armkeil.blob.core.windows.net/developer/Files/downloads/gnu/${ARM_VERSION}/binrel/${ARM_TOOL_CHAIN}.${TAR_EXT}
    fi
    
    if [ ! -d "${ARM_TOOL_CHAIN}" ] && [ -f "${ARM_TOOL_CHAIN}.${TAR_EXT}" ]; then
      tar -xvf ${ARM_TOOL_CHAIN}.${TAR_EXT}
    else
      echo "~/tmp/${ARM_TOOL_CHAIN}.${TAR_EXT} file NOT found! (checking directory)"
    fi
    
    if [ -d ${ARM_TOOL_CHAIN} ]; then
      mv ${ARM_TOOL_CHAIN} ~/tools/${ARM_PATH_TGT}
      if ! grep -q "${TGT}" "${HOME}/.bashrc_local"; then
        echo '# --------------------------------'  >> ~/.bashrc_local
        echo "# ${TGT}" >> ~/.bashrc_local
        echo '# ARM Toolchain' >> ~/.bashrc_local
        echo 'export PATH=${HOME}/tools/${ARM_PATH_TGT}/bin:$PATH' >> ~/.bashrc_local
      fi
    fi
  done
fi

echo "----------------------------------------------------------------------------------------------------"
echo "Done"
echo "----------------------------------------------------------------------------------------------------"
