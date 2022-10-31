#!/bin/bash
# references https://askubuntu.com/a/1329800"
echo "----------------------------------------------------------------------------------------------------"
echo "Create a new VM with enough HDD space to copy old WSL <disk>.vhdx file"
echo "After VM creation, copy <disk>.vhdx file new VM (https://winscp.net/eng/index.php)"
echo "Copy to ~/tmp/ext4.vhdx (press <Y> after locating the file, before copying next in this script)"
echo "How to locate WSL2 <disk>.vhdx drive on Windows (https://learn.microsoft.com/en-us/windows/wsl/vhd-size)"
echo "On Powershell: Get-AppxPackage -Name "*Ubuntu*" | Select PackageFamilyName"
echo "WIN+S (search): %LOCALAPPDATA%"
echo "-> find HDD with %LOCALAPPDATA%\Packages\<PackageFamilyName>\LocalState\<disk>.vhdx"
echo "-> <disk> is usually ext4.vhdx"
echo "----------------------------------------------------------------------------------------------------"
read_data=true
while $read_data; do
  read -p "Is this the new VM, ready to proceed (y/n) (Ctrl+c to exit)" ok
  if [ "${ok}" == "y" ]; then
    read_data=false
  else
    read_data=true
  fi
done

echo "----------------------------------------------------------------------------------------------------"
echo "Updating and installing OpenSSH-server (copy file) and libguestfs (mount vhdx <disk>)"
sudo -S apt update -y && sudo -S apt upgrade -y && sudo apt dist-upgrade -y && sudo apt autoremove -y
sudo -S apt install openssh-server libguestfs-tools
mkdir -p ${HOME}/tmp
cd ${HOME}/tmp
echo "----------------------------------------------------------------------------------------------------"
echo "Copy <disk>.vhdx to ~/tmp/ext4.vhdx (WinSCP)"
read -p "Press ENTER after copy completed..." ok
echo "Mounting <disk>: ~/tmp/ext4.vhdx -> /mnt/vhdxdrive"
sudo mkdir -p /mnt/vhdxdrive
sudo guestmount --add ext4.vhdx -i --rw /mnt/vhdxdrive
sudo ls /mnt/vhdxdrive -lah

echo "----------------------------------------------------------------------------------------------------"
echo "Drive ready, access with sudo usually required:"
echo "sudo ls /mnt/vhdxdrive            # (list files)"
echo "sudo cp -r /mnt/vhdxdrive/* ./    # (copy files)"
echo "sudo chown -R user:group dir_name # (change owner:group to access files)"
echo "----------------------------------------------------------------------------------------------------"
echo "After done:"
echo "sudo guestunmount /mnt/vhdxdrive  # (unmount <disk>)"
echo "sudo rm -fr /mnt/vhdxdrive        # (remove mount dir)"
echo "sudo rm ~/tmp/ext4.vhdx           # (free space, as required!!!)"
echo "----------------------------------------------------------------------------------------------------"
