
#!/bin/bash
# --------------------------------------------------------------------------------
VENV_TGT="hdl"
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

# --------------------------------------------------------------------------------
# https://sv-lang.com/building.html

# Dependecies
sudo -S snap install cmake --classic

# Check if directory exists
cd ${HOME}/repos
if [ ! -d "slang" ]; then
  git clone https://github.com/MikePopoloski/slang.git
fi

# Build & Install
cd slang
git pull
#cmake -B build
#cmake --build build
cmake -B build -DSLANG_INCLUDE_DOCS=ON
cmake --build build --target docs
cmake --install build --strip --prefix ${HOME}/tools/slang

# Add path
if ! grep -q "slang" "${HOME}/.bashrc_local"; then
  echo '# --------------------------------' >> ~/.bashrc_local
  echo '# slang' >> ~/.bashrc_local
  echo 'export PATH=${HOME}/tools/slang/bin:$PATH' >> ~/.bashrc_local
fi

echo "--------------------------------------------------"
echo "Installing pyslang to ${VIRTUAL_ENV}"
pip install pyslang

echo "--------------------------------------------------"
echo "Done"
echo "--------------------------------------------------"
