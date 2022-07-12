#!/bin/bash
# Set path
name="verilator"
install_path=$1
tag=$2

if [ -z "${install_path}" ]; then
  install_path="${HOME}/repos"
fi

if [ -z "${tag}" ]; then
  echo "Installing ${name} (latest tag/version)"
else
  echo "Installing ${name} ${tag}"
fi

if [ ! -d "${install_path}" ]; then
  mkdir -p ${install_path}
fi
cd ${install_path}

# App dependencies
sudo -S apt purge -y verilator
sudo -S apt install -y perl autoconf flex bison ccache
sudo -S apt install -y  libgoogle-perftools-dev numactl perl-doc
sudo -S apt install -y libfl2 libfl-dev zlibc zlib1g zlib1g-dev

# Check if directory exists
if [ ! -d "${name}" ]; then
  cd ${install_path}
  git clone https://github.com/eideticom/${name}
fi

# Setup env
unset VERILATOR_ROOT
cd ${name}
git checkout master; git pull
git fetch
if [ -z "${tag}" ]; then
  tag=$(git describe --abbrev=0)
fi
git checkout ${tag}

# Install App
autoconf         # Create ./configure script
./configure      # Configure and create Makefile
make -j$(noproc)
sudo -S make install

echo "--------"
echo "Done!"
echo "--------"
