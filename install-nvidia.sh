sudo dnf update -y
sudo dnf install kernel-devel
sudo dnf install akmod-nvidia xorg-x11-drv-nvidia-cuda
modinfo -F version nvidia
sudo systemctl enable nvidia-hibernate.service nvidia-suspend.service nvidia-resume.service nvidia-powerd.service
sudo dnf install xorg-x11-drv-nvidia-power
sudo systemctl enable nvidia-{suspend,resume,hibernate}
sudo dnf install kmodtool akmods mokutil openssl
sudo kmodgenca -a
sudo mokutil --import /etc/pki/akmods/certs/public_key.der
sleep 5m
sudo systemctl reboot
