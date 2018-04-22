#!/bin/bash

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <hostname> <cluster-name>"
    exit 1
fi

NAME=$1
CLUSTER=$2
OSVERSION=centos-7.4
ARCHITECTURE=x86_64

# restart domain
virsh reboot ${NAME}-${OSVERSION}-${ARCHITECTURE}

if [ ! $? -eq 0 ]; then
    echo "Trying to start"
    virsh start ${NAME}-${OSVERSION}-${ARCHITECTURE}
fi

