#!/bin/bash
# There is a problem with Fedora containers, that systemd cannot be upgraded inside the container.
sed -i "s/lxc.cap.drop = setfcap/#lxc.cap.drop = setfcap/g" /usr/share/lxc/config/fedora.common.conf

# fix a problem for CentOS7 containers. see https://github.com/lxc/lxc/commit/a4aed378f802ad9caf74ee1c20dc74a6f9d7ca17
sed -i "s/lxc.cap.drop = mac_admin mac_override setfcap setpcap/lxc.cap.drop = mac_admin mac_override setfcap/g" /usr/share/lxc/config/centos.common.conf
