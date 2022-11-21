
#!/bin/bash
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
