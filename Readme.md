Purpose
-------

These scripts are useful to manage your own server, with several Linux containers.

CheatSheet for my LXC scripts
---------------------------------

* Create a machine (with networking etc): `~/scripts/initFedora.sh $name $id`
* Start a machine: `lxc-start --name $name`
* Destroy a machine: `lxc-destroy --name $name`
* List all machines: `lxc-ls`
