#!/bin/bash -e

echo > ${ROOTFS_DIR}/etc/tor/torrc << EOF
Log notice file /var/log/tor/notices.log
VirtualAddrNetwork 172.192.0.0/10
AutomapHostsSuffixes .onion,.exit
AutomapHostsOnResolve 1
TransPort 9040
TransListenAddress 172.0.0.1
DNSPort 53
DNSListenAddress 172.0.0.1
EOF

on_chroot << EOF
    iptables -F
    iptables -t nat -F
    iptables -t nat -A PREROUTING -i usb0 -p udp --dport 53 -j REDIRECT --to-ports 53
    iptables -t nat -A PREROUTING -i usb0 -p tcp --syn -j REDIRECT --to-ports 9040
    iptables-save > /etc/iptables.ipv4.nat
    touch /var/log/tor/notices.log
    chown debian-tor /var/log/tor/notices.log
    chmod 644 /var/log/tor/notices.log
    systemctl enable tor
EOF