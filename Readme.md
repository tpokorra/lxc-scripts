Purpose
-------

These scripts are useful to manage your own server, with several Linux containers.

CheatSheet for my LXC scripts
---------------------------------

* Initialise the host IPTables so that they will be survive a reboot: `~/scripts/initIPTables.sh`
* Create a machine (with networking etc): `~/scripts/initFedora.sh $name $id`
* machines are created in `/var/lib/lxc/$name`, see the file `config` and the directory `rootfs`
* Start a machine: `lxc-start --name $name`
* Start a machine without console: `lxc-start -d --name $name`
* Destroy a machine: `lxc-destroy --name $name`
* List all machines: `lxc-ls -f`
