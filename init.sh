#!/bin/bash
echo 'inet 10.0.0.1 255.255.255.0 10.0.0.255' > /etc/hostname.em0
echo 'dhcp' > /etc/hostname.em1
echo 'dhcp' > /etc/hostname.em2
cat << EOF > /etc/sysctl.conf
ddb.panic=0 # Don't panic, try and reboot
kern.bufcachepercent=90
net.inet.ip.forwarding=1
net.inet.ip.ifq.maxlen=768
net.inet.udp.recvspace=131072
net.inet.udp.sendspace=131072
EOF
rcctl enable dhcpd
rcctl set dhcpd flags em0
cat << EOF > /etc/dhcpd.conf
option domain-name-servers 10.0.0.1;
subnet 10.0.0.1 netmask 255.255.255.0 {
	option routers 10.0.0.1;
	range 10.0.0.100 10.0.0.220;
}
EOF
pkg_add ifstated
cp ./ifstated.conf /etc/
rcctl enable ifstated
cat << EOF > /var/unbound/etc/unbound.conf
server:
	interface: 10.0.0.1
	interface: 127.0.0.1
	access-control: 10.0.0.0/24 allow
	do-not-query-localhost: no
	hide-identity: yes
	hide-version: yes
forward-zone:
	name: "."
	forward-addr: 8.8.8.8@53
EOF
rcctl enable unbound
cp ./pf.conf /etc/
cd /usr
cvs -qd anoncvs@anoncvs.usa.openbsd.org:/cvs get -rOPENBSD_`uname -r | sed 's/\./_/'` -P src
cd /usr/src
cvs -q up -rOPENBSD_`uname -r | sed 's/\./_/'` -Pd
cd /usr/src/sys/arch/`machine`/conf
config GENERIC.MP
cd ../compile/GENERIC.MP
make clean && make && make install
cd /usr/src
make obj
cd /usr/src/etc && env DESTDIR=/ make distrib-dirs
cd /usr/src
make build
rm -rf /usr/xobj/*
rm -rf /usr/obj/*
reboot

