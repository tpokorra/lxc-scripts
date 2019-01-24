#!/bin/bash
for f in /var/log/backup-*; do echo $f; cat $f; done | more
