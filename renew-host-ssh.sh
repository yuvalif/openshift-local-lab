#!/bin/bash

if [ ! $# -eq 2 ]
  then
    echo "Usage: $0 <host> <user>"
    exit 1
fi

# deletion may fail if we run for the first time
ssh-keygen -R $1 2> /dev/null
ssh-keygen -R `dig +short $1` 2> /dev/null
# copy the key to the host
ssh-copy-id -o "StrictHostKeyChecking no" $2@$1
# ssh to the host to verify it works
ssh -o "StrictHostKeyChecking no" $2@$1 'uname -a'

