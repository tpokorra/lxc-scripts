Purpose
-------

These scripts are useful to manage your own server, with several Linux containers.

Installation
------------

* Either clone this code repository: `cd ~; git clone https://github.com/tpokorra/lxc-scripts.git scripts`
* Or install a package from LBS: https://lbs.solidcharity.com/package/tpokorra/lbs/lxc-scripts
 * There is a lxc-scripts package for CentOS7, Fedora 22, and Ubuntu 14.04, with instructions how to install the package
 * To make things easier, I usually create a symbolic link: `cd ~; ln -s /usr/share/lxc-scripts scripts`

After installing the package, run these scripts for initializing the firewall and some fixes for the LXC templates:

    /usr/share/lxc-scripts/initLXC.sh
    /usr/share/lxc-scripts/initIPTables.sh

CheatSheet for my LXC scripts
---------------------------------

* Initialise the host IPTables so that they will be survive a reboot: `~/scripts/initIPTables.sh`
* Small fixes to the LXC system for CentOS7 and Fedora containers, and create ssh keys: `~/scripts/initLXC.sh`
* Create a container (with networking etc): `~/scripts/initFedora.sh $name $id`
 * Call the script without parameters to see additional parameters, eg to specify the version of the OS etc: `~/scripts/initFedora.sh`
 * There are scripts for creating Fedora, CentOS, Debian, and Ubuntu containers
* Containers are created in `/var/lib/lxc/$name`, see the file `config` and the directory `rootfs`
* Start a container: `lxc-start --name $name`
* Start a container without console: `lxc-start -d --name $name`
* Stop a container: `lxc-stop -n $name`
* Destroy a container: `lxc-destroy --name $name`
* List all containers, with running state and IP address: `lxc-ls -f`
 * alternatively, there is this script: `~/scripts/listcontainers.sh` which works even on CentOS where python3 is not (yet) available
 * this also shows the OS of the container
