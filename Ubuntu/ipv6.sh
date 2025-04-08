#! /bin/bash
sudo -i
read -p "Nhap gia tri ipv6: " ipv6
read -p "Nhap gia tri netmask: " netmask
read -p "Nhap gia tri gateway: " gateway
echo "iface eth0 inet6 static
address $ipv6
netmask $netmask
gateway $gateway" >> /etc/network/interfaces
service networking restart
