#!/bin/bash
# https://superuser.com/a/529183/1049338

# On VM (guest)
echo "Zeroing..."
dd if=/dev/zero of=/var/tmp/bigemptyfile bs=4096k ; rm /var/tmp/bigemptyfile

echo "Stop VM"
echo 'On Host'
echo 'VBoxManage.exe modifymedium --compact c:\path\to\thedisk.vdi'

read -p "shutdown (y/n)? " ok
if [ "${ok}" == "y" ]; then
  sudo shutdown now
fi
