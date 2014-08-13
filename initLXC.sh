#!/bin/bash
# There is a problem with Fedora containers, that systemd cannot be upgraded inside the container.
sed -i "s/lxc.cap.drop = setfcap/#lxc.cap.drop = setfcap/g" /usr/share/lxc/config/fedora.common.conf
