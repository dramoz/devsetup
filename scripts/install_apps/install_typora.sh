#!/bin/bash
# https://typora.io/#linux
wget -qO - https://typora.io/linux/public-key.asc | sudo tee /etc/apt/trusted.gpg.d/typora.asc

# add Typora's repository
sudo -S add-apt-repository 'deb https://typora.io/linux ./'
sudo -S apt update -y

# install typora
sudo -S apt install -y typora
