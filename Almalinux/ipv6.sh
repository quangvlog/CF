#!/bin/bash
read -p "Nhap dia chi IPv6: " IPV6ADDR
read -p "Nhap Default Gateway cua IPv6: " IPV6_DEFAULTGW

echo "IPV6_FAILURE_FATAL=no
IPV6_ADDR_GEN_MODE=stable-privacy
IPV6ADDR=$IPV6ADDR/64
IPV6_DEFAULTGW=$IPV6_DEFAULTGW" >> /etc/sysconfig/network-scripts/ifcfg-ens3
systemctl restart NetworkManager.service
echo "Da tao ipv6 thanh cong"
