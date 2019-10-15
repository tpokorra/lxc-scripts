#!/bin/bash
for f in /var/log/backup-*; do
	echo
	echo "====================================="
	echo $f
        echo "====================================="
	cat $f;
done | more
