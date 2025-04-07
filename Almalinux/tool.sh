#! /bin/bash
fallocate -l 4G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile none swap sw 0 0' >> /etc/fstab
echo "Da tao file swap thanh cong"
sudo dnf install -y wget gcc make tar net-tools
echo "Da cai cac goi can thiet..."
