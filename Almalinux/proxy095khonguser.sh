#!/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

random() {
    tr </dev/urandom -dc A-Za-z0-9 | head -c5
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
    echo "installing 3proxy"
    git clone https://github.com/z3apa3a/3proxy
    cd 3proxy
    ln -s Makefile.Linux Makefile
    make
    sudo make install
    cd $WORKDIR
}

gen_3proxy() {
    cat <<EOF
daemon
maxconn 4000
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
auth none

$(awk -F "/" '{print "allow *\n" \
"proxy -6 -n -a -p" $4 " -i" $3 " -e"$5"\n" \
"flush\n"}' ${WORKDATA})
EOF
}

gen_proxy_file_for_user() {
    cat >proxy.txt <<EOF
$(awk -F "/" '{print $3 ":" $4}' ${WORKDATA})
EOF
}

gen_data() {
    seq $FIRST_PORT $LAST_PORT | while read port; do
        echo "//$IP4/$port/$(gen64 $IP6)"
    done
}

gen_ifconfig() {
    cat <<EOF
$(awk -F "/" '{print "ifconfig ens3 inet6 add " $5 "/64"}' ${WORKDATA})
EOF
}

echo "installing apps"

install_3proxy

echo "working folder = /home/quangvlog"
WORKDIR="/home/quangvlog"
WORKDATA="${WORKDIR}/data.txt"
mkdir -p $WORKDIR && cd $WORKDIR

IP4=$(curl -4 -s icanhazip.com)
IP6=$(curl -6 -s icanhazip.com | cut -f1-4 -d':')

echo "Internal IP = ${IP4}. External sub for IP6 = ${IP6}"

while :; do
  read -p "Nhap FIRST_PORT, nen chon giua 21000 va 61000: " FIRST_PORT
  [[ $FIRST_PORT =~ ^[0-9]+$ ]] || { echo "FIRST_PORT kha dung"; continue; }
  if ((FIRST_PORT >= 21000 && FIRST_PORT <= 61000)); then
    break
  else
    echo "Vui long nhap lai"
  fi
done

read -p "Ban muon tao bao nhieu proxy?: " COUNT

LAST_PORT=$(($FIRST_PORT + $COUNT - 1))
echo "Ban se tao $COUNT Proxy voi Port tu $FIRST_PORT den $LAST_PORT"

gen_data >$WORKDIR/data.txt
gen_ifconfig >$WORKDIR/boot_ifconfig.sh
chmod +x boot_*.sh /etc/rc.d/rc.local

gen_3proxy >/usr/local/3proxy/conf/3proxy.cfg

cat >>/etc/rc.d/rc.local <<EOF
bash ${WORKDIR}/boot_ifconfig.sh
ulimit -n 100480
/usr/bin/3proxy /usr/local/3proxy/conf/3proxy.cfg
EOF

chmod +x /etc/rc.d/rc.local
systemctl enable rc-local
systemctl start rc-local

bash /etc/rc.local

gen_proxy_file_for_user
rm -rf /root/setup.sh
rm -rf /root/3proxy

echo "Starting Proxy"
