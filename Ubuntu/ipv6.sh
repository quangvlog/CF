#! /bin/bash
sudo rm /etc/network/interfaces
read -p "Nhap gia tri ipv6: " ipv6
read -p "Nhap gia tri netmask: " netmask
read -p "Nhap gia tri gateway: " gateway
touch /etc/network/interfaces
echo "auto lo
iface lo inet loopback
auto eth0
iface eth0 inet dhcp
iface eth0 inet6 static
address $ipv6
netmask $netmask
gateway $gateway" >> /etc/network/interfaces
service networking restart
echo "Da tao ipv6 thanh cong"
