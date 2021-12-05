#!/bin/bash -e

on_chroot << EOF
    echo "dtoverlay=dwc2" | tee -a /boot/config.txt
    echo "dwc2" | tee -a /etc/modules
    echo "libcomposite" | tee -a /etc/modules
EOF