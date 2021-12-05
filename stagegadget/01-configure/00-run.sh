#!/bin/bash -e

echo >> ${ROOTFS_DIR}/usr/bin/usb_gadget << EOF
#!/bin/bash
cd /sys/kernel/config/usb_gadget/
mkdir -p onionpi
cd onionpi
echo 0x1d6b > idVendor  # Linux Foundation
echo 0x0104 > idProduct # Multifunction Composite Gadget
echo 0x0100 > bcdDevice # v1.0.0
echo 0x0200 > bcdUSB    # USB2
mkdir -p strings/0x409
echo "onionpi100" > strings/0x409/serialnumber
echo "Andrew St Clair > strings/0x409/manufacturer
echo "Onion Pi Router" > strings/0x409/product
mkdir -p configs/c.1/strings/0x409
echo "Config 1: ECM Network" > configs/c.1/strings/0x409/configuration
echo 250 > configs/c.1/MaxPower

# Serial Interface
mkdir -p functions/acm.usb0
ln -s functions/acm.usb0 configs/c.1/

# Ethernet Interface
mkdir -p functions/ecm.usb0
# first byte must be even
HOST="48:6f:73:74:50:43" # Host PC
SELF="42:61:64:55:53:42" # Onion Pi
echo $HOST > functions/ecm.usb0/host_addr
echo $SELF > functions/ecm.usb0/dev_addr
ln -s functions/ecm.usb0 configs/c.1

ls /sys/class/udc > UDC


systemctl start getty@ttyGS0.service
ifconfig usb0 172.0.0.1 netmask 255.255.255.0 up
EOF

echo >> ${ROOTFS_DIR}/etc/systemd/system/usb_gadget.service << EOF
[Unit]
Description=Setup Gadget

[Service]
Type=simple
RemainAfterExit=yes
ExecStart=/usr/bin/usb_gadget
TimeoutStartSec=0

[Install]
WantedBy=default.target
EOF

echo >> ${ROOTFS_DIR}/etc/dhcp/dhcpd.conf << EOF
default-lease-time 600;
max-lease-time 7200;

subnet 172.0.0.1 netmask 255.255.255.0 {
    range 172.0.0.2 172.0.0.100;
    option domain-name-servers 172.0.0.1;
    option routers 172.0.0.1;
}
EOF

on_chroot << EOF
    chmod +x /usr/bin/usb_gadget
    systemctl daemon-reload
    systemctl enable usb_gadget.service
EOF