#!/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

random() {
	tr </dev/urandom -dc A-Za-z0-9 | head -c12
	echo
}

array=(1 2 3 4 5 6 7 8 9 0 a b c d e f)
gen64() {
	ip64() {
		echo "${array[$RANDOM % 16]}${array[$RANDOM % 16]}${array[$RANDOM % 16]}${array[$RANDOM % 16]}"
	}
	echo "$1:$(ip64):$(ip64):$(ip64):$(ip64)"
}

install_3proxy() {
    echo "Dang cai dat 3proxy..."
    git clone https://github.com/z3APA3A/3proxy
    cd 3proxy
    ln -s Makefile.Linux Makefile
    make
    make install
    cd $WORKDIR
}

download_proxy() {
    curl -F "file=@proxy.txt" https://file.io
}

gen_3proxy() {
    mkdir -p /usr/local/3proxy/conf
    cat <<EOF >/usr/local/3proxy/conf/3proxy.cfg
daemon
maxconn 2000
nserver 1.1.1.1
nserver 8.8.4.4
nserver 2001:4860:4860::8888
nserver 2001:4860:4860::8844
nscache 65536
timeouts 1 5 30 60 180 1800 15 60
setgid 65535
setuid 65535
stacksize 6291456
flush
auth strong

users $(awk -F "/" 'BEGIN{ORS="";} {print $1 ":CL:" $2 " "}' ${WORKDATA})

$(awk -F "/" '{print "auth strong\n" \
"allow " $1 "\n" \
"proxy -6 -n -a -p" $4 " -i" $3 " -e"$5"\n" \
"flush\n"}' ${WORKDATA})
EOF
}

gen_proxy_file_for_user() {
    awk -F "/" '{print $3 ":" $4 ":" $1 ":" $2 }' ${WORKDATA} > proxy.txt
}

gen_data() {
    seq $FIRST_PORT $LAST_PORT | while read port; do
        echo "user$port/$(random)/$IP4/$port/$(gen64 $IP6)"
    done
}

gen_iptables() {
    awk -F "/" '{print "iptables -I INPUT -p tcp --dport " $4 " -m state --state NEW -j ACCEPT"}' ${WORKDATA}
}

gen_ifconfig() {
    awk -F "/" '{print "ifconfig eth0 inet6 add " $5 "/64"}' ${WORKDATA}
}

echo "Installing required packages..."
yum -y install git gcc net-tools zip curl make tar >/dev/null

cat << EOF > /etc/rc.d/rc.local
#!/bin/bash
touch /var/lock/subsys/local
EOF

WORKDIR="/home/quangvlog"
WORKDATA="${WORKDIR}/data.txt"
mkdir -p $WORKDIR && cd $WORKDIR

IP4=$(curl -4 -s icanhazip.com)
IP6=$(curl -6 -s icanhazip.com | cut -f1-4 -d':')

echo "IPv4 = $IP4 | IPv6 prefix = $IP6"

while :; do
  read -p "Nhap FIRST_PORT giua 21000 va 61000: " FIRST_PORT
  [[ $FIRST_PORT =~ ^[0-9]+$ ]] || { echo "FIRST_PORT kha dung"; continue; }
  if ((FIRST_PORT >= 21000 && FIRST_PORT <= 61000)); then
    break
  else
    echo "Vui long nhap lai"
  fi
done

read -p "Ban muon tao bao nhieu proxy?: " COUNT

LAST_PORT=$(($FIRST_PORT + $COUNT))
echo "Port cua ban se tu $FIRST_PORT den $LAST_PORT"

install_3proxy
gen_data > $WORKDATA
gen_iptables > boot_iptables.sh
gen_ifconfig > boot_ifconfig.sh
chmod +x boot_*.sh /etc/rc.local

gen_3proxy

cat >>/etc/rc.local <<EOF
bash ${WORKDIR}/boot_iptables.sh
bash ${WORKDIR}/boot_ifconfig.sh
ulimit -n 1000048
/usr/bin/3proxy /usr/local/3proxy/conf/3proxy.cfg
EOF

chmod +x /etc/rc.local
bash /etc/rc.local

gen_proxy_file_for_user
echo "Bat dau chay Proxy"
download_proxy
