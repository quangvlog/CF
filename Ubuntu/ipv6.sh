#! /bin/bash
cd /etc/network
read -p "Nhap gia tri cho bien ipv6: " ipv6
read -p "Nhap gia tri cho bien netmask: " netmask
read -p "Nhap gia tri cho bien gateway: " gateway
touch a
echo -e "iface eth0 inet6 static\nipv6 $ipv6\nnetmask $netmask\ngateway $gateway" >> interfaces
service networking restart
