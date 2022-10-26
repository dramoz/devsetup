#!/bin/bash
echo "----------------------------------------------------------------------------------------------------"

ubuntu_release=$(lsb_release -r)
ubuntu_ver=$(cut -f2 <<< "$ubuntu_release")
echo "$ubuntu_ver"
echo "Ubuntu: ${ubuntu_ver}"

echo "----------------------------------------------------------------------------------------------------"
if [ "`echo "${ubuntu_ver} >= 22.04" | bc`" -eq 1 ]; then
  echo "Ubuntu version >= 22.04"
else
  echo "Ubuntu version less than 22.04"
fi
echo "----------------------------------------------------------------------------------------------------"
