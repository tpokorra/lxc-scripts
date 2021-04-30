Purpose
-------

These scripts are useful to manage your own server, with several Linux containers.

Installation
------------

* Either clone this code repository: `cd ~; git clone https://github.com/tpokorra/lxc-scripts.git scripts`
* Or install a package from LBS: https://lbs.solidcharity.com/package/tpokorra/lbs/lxc-scripts
 * There is a lxc-scripts package for CentOS7, and Ubuntu 20.04, with instructions how to install the package
 * To make things easier, I usually create a symbolic link: `cd ~; ln -s /usr/share/lxc-scripts scripts`

After installing the package, run these scripts for initializing the firewall and some fixes for the LXC templates:

    /usr/share/lxc-scripts/initLXC.sh
    /usr/share/lxc-scripts/initIPTables.sh

CheatSheet for my LXC scripts
---------------------------------

* Initialise the host IPTables so that they will be survive a reboot: `~/scripts/initIPTables.sh`
* Small fixes to the LXC system for CentOS7 containers, and create ssh keys: `~/scripts/initLXC.sh`
* Create a container (with networking etc): `~/scripts/initCentOS.sh $name $id`
 * Call the script without parameters to see additional parameters, eg to specify the version of the OS etc: `~/scripts/initCentOS.sh`
 * There are scripts for creating CentOS, Debian, and Ubuntu containers
* Containers are created in `/var/lib/lxc/$name`, see the file `config` and the directory `rootfs`
* Start a container: `lxc-start --name $name`
* Start a container without console: `lxc-start -d --name $name`
* Stop a container: `lxc-stop -n $name`
* Destroy a container: `lxc-destroy --name $name`
* List all containers, with running state and IP address: `lxc-ls -f`
 * alternatively, there is this script: `~/scripts/listcontainers.sh` which works even on CentOS where python3 is not (yet) available
 * this also shows the OS of the container
 * ~/scripts/listcontainers.sh running: shows only running containers
 * ~/scripts/listcontainers.sh stopped: shows only stopped containers
* Stop all containers: `~/scripts/stopall.sh`

Snapshots:
* are stored in `/var/lib/lxcsnaps/`
* first stop the container: `lxc-stop -n $name`
* then create the snapshot: `lxc-snapshot -n $name`
 * create with comment: `echo "mycomment" > /tmp/comment && lxc-snapshot -n $name -c /tmp/comment && rm -f /tmp/comment`
* list all snapshots: `lxc-snapshot -LC -n $name`
* restore a snapshot: `lxc-snapshot -n $name -r snap@`
* create a new container from snapshot: `lxc-snapshot -n $name -r snap@ new$name`
* delete a snapshot: `lxc-snapshot -n $name -d snap@`
