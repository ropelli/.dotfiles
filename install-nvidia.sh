#!/bin/bash
set -ex
sudo dnf remove \*nvidia\* --exclude nvidia-gpu-firmware -y
sudo dnf update -y
sudo dnf install kernel-devel -y
sudo dnf install akmod-nvidia xorg-x11-drv-nvidia-cuda -y
sleep 4m
sudo modinfo -F version nvidia
sudo systemctl enable nvidia-hibernate.service nvidia-suspend.service nvidia-resume.service nvidia-powerd.service
sudo dnf install xorg-x11-drv-nvidia-power
sudo systemctl enable nvidia-{suspend,resume,hibernate}
sudo dnf install kmodtool akmods mokutil openssl
sudo kmodgenca -a --force
sudo mokutil --import /etc/pki/akmods/certs/public_key.der
echo 'ready to reboot'
# sudo systemctl reboot
