#!/bin/bash
echo "--------------------------------------------------"
echo "Install apps for R&D, and then reboot"
echo "--------------------------------------------------"

echo "Installing VS code..."
sudo -S snap install code --classic

echo "--------------------------------------------------"
read -p "Install Brave Browser (y/n)? " ok
if [ "${ok}" == "y" ]; then
  sudo -S apt -y install apt-transport-https curl
  sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
  echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg arch=amd64] https://brave-browser-apt-release.s3.brave.com/ stable main"|sudo tee /etc/apt/sources.list.d/brave-browser-release.list
  sudo -S apt update -y
  sudo -S apt install -y brave-browser
fi

echo "--------------------------------------------------"
read -p "Done for the moment, reboot (y/n)? " ok
if [ "${ok}" == "y" ]; then
  sudo reboot
else
  echo "Please reboot at your convenience..."
fi

