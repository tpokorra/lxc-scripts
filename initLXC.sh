#!/bin/bash
# There is a problem with Fedora containers, that systemd cannot be upgraded inside the container.
sed -i "s/lxc.cap.drop = setfcap/#lxc.cap.drop = setfcap/g" /usr/share/lxc/config/fedora.common.conf

# fix a problem for CentOS7 containers. see https://github.com/lxc/lxc/commit/a4aed378f802ad9caf74ee1c20dc74a6f9d7ca17
# also remove setfcap, see https://bugzilla.redhat.com/show_bug.cgi?id=648654#c31 (httpd did not install for Kolab on CentOS7)
sed -i "s/lxc.cap.drop = mac_admin mac_override setfcap setpcap/lxc.cap.drop = mac_admin mac_override/g" /usr/share/lxc/config/centos.common.conf

# fix a problem of Fedora 21, see https://bugzilla.redhat.com/show_bug.cgi?id=1176634
# patching /usr/share/lxc/templates/lxc-fedora
patch -p0 lxc-fedora.patch
