#!/bin/bash
# --------------------------------------------------------------------------------
# Tools versions
# --------------------------------------------------------------------------------

# Download Cable Drivers
sudo -S touch /etc/udev/rules.d/92-usbblaster.rules
sudo -S echo 'SUBSYSTEMS=="usb", ATTRS{idVendor}=="09fb", ATTRS{idProduct}=="6010", MODE="0666"' >> /etc/udev/rules.d/92-usbblaster.rules
sudo -S echo 'SUBSYSTEMS=="usb", ATTRS{idVendor}=="09fb", ATTRS{idProduct}=="6810", MODE="0666"' >> /etc/udev/rules.d/92-usbblaster.rules
