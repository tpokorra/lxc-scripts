#!/bin/bash
# load the private key from .ssh/id_rsa
# do not load this automatically in ~/.bash_rc for root, if you are using this server as a build server for LBS. just run it manually
eval `ssh-agent`
ssh-add

