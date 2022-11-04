#!/bin/bash
# --------------------------------------------------------------------------------
# Tools versions
verible_ver="v0.0-2479-g92928558"

oss_cad_suite_ver="oss-cad-suite-linux-x64-20221102"
oss_cad_suite_dwnld_dir="2022-11-02"

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
  read -p "No virtualenv active detected, use virtualenv:dev (y/n)? " ok
  if [ "${ok}" == "y" ]; then
    source .virtualenvs/dev/bin/activate
  else
    read -p "Create/use virtualenv:hdl (y/n)? " ok
    if [ "${ok}" == "y" ]; then
      if [ ! -d "${HOME}/.virtualenvs/hdl/" ]; then
        echo "virtualenv:hdl not found, creating..."
        mkvirtualenv hdl
        source .virtualenvs/hdl/bin/activate
        pip install -r ~/dev/devsetup/virtualenv/dev_requirements.txt
      else
        source .virtualenvs/hdl/bin/activate
      fi
    else
      echo "This scripts only with virtualenv"
      exit 1
    fi
  fi
fi

echo "----------------------------------------------------------------------------------------------------"
read -p "Install VisualCode TerosHDL (https://terostechnology.github.io/terosHDLdoc/) (y/n)? " ok
if [ "${ok}" == "y" ]; then
  echo ".................................................."
  echo "Installing on python virtualenv: ${VIRTUAL_ENV}"
  echo ".................................................."
  pip install teroshdl
  code --install-extension teros-technology.teroshdl
  

fi

echo "--------------------------------------------------"
read -p "VUnit (y/n)? " ok
if [ "${ok}" == "y" ]; then
  pip install vunit_hdl
fi

echo "--------------------------------------------------"
read -p "Verible (SV linter/formatter) (y/n)? " ok
if [ "${ok}" == "y" ]; then
  cd ${HOME}/tools
  if [ ! -d "verible" ] && [ ! -f "${HOME}/tmp/verible.tar.gz" ]; then
    echo "Download: Verible (TAR ~10MB) (${verible_ver})"
    wget -O ${HOME}/tmp/verible.tar.gz https://github.com/chipsalliance/verible/releases/download/${verible_ver}/verible-${verible_ver}-Ubuntu-22.04-jammy-x86_64.tar.gz
    tar -xvzf ${HOME}/tmp/verible.tar.gz
    mv verible-${verible_ver} verible
  fi
  
  if ! grep -q "verible" "${HOME}/.bashrc_local"; then
    echo '# --------------------------------' >> ~/.bashrc_local
    echo '# verible' >> ~/.bashrc_local
    echo 'export PATH=${HOME}/tools/verible/bin:$PATH' >> ~/.bashrc_local
  fi
  
  echo "--------------------------------------------------"
  echo "Invoke tools from terminal with:"
  echo "$ verible-*"
  echo "$ verible-verilog-lint --version"
  echo "--------------------------------------------------"
  echo "Paths for VS Code TerosHDL: "
  echo "  Formatter Settings.Verilog/SV Verible formatter: ~/tools/verible/bin/verible-verilog-format"
  echo "--------------------------------------------------"
fi

echo "--------------------------------------------------"
read -p "OSS CAD Suite (Yosys, schematic viewer) (https://github.com/YosysHQ/oss-cad-suite-build) (y/n)? " ok
if [ "${ok}" == "y" ]; then
  cd ${HOME}/tools
  if [ ! -d "oss-cad-suite" ] && [ ! -f "${HOME}/tmp/oss_cad_suite_ver.tgz" ]; then
    echo "Download: OSS CAD Suite (TAR ~480MB) (${oss_cad_suite_ver})"
    wget -O ${HOME}/tmp/oss_cad_suite_ver.tgz https://github.com/YosysHQ/oss-cad-suite-build/releases/download/${oss_cad_suite_dwnld_dir}/${oss_cad_suite_ver}.tgz
    tar -xvzf ${HOME}/tmp/oss_cad_suite_ver.tgz
  fi
  
  if ! grep -q "oss-cad-suite" "${HOME}/.bashrc_local"; then
    echo '# --------------------------------' >> ~/.bashrc_local
    echo '# oss-cad-suite' >> ~/.bashrc_local
    echo '# Set PATH at the end, as oss-cad has several tools' >> ~/.bashrc_local
    echo '# that will conflict with other installations (e.g. Verilator, RISC-V toolchain, ...' >> ~/.bashrc_local
    echo 'export PATH=$PATH:${HOME}/tools/verible/bin' >> ~/.bashrc_local
  fi
  
  echo "--------------------------------------------------"
  echo "Invoke tools from terminal with:"
  echo "$ *"
  echo "$ yosys --version"
  echo "--------------------------------------------------"
  echo "run from OSS CAD Suite environment"
  echo "$ source tools/oss-cad-suite/environment"
  echo "--------------------------------------------------"
  echo "Path(s) for VS Code TerosHDL: "
  echo "- Tools: GHDL, SymbiYosys, Yosys"
  echo "  path: ~/tools/oss-cad-suite/bin/"
  echo "--------------------------------------------------"
fi

echo "--------------------------------------------------"
read -p "Done for the moment, reboot (y/n)? " ok
if [ "${ok}" == "y" ]; then
  echo "Sanity reboot..."
  sudo reboot
fi
