#!/bin/bash

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <hostname> <cluster-name>"
    exit 1
fi

NAME=$1
CLUSTER=$2
HOST=$1.$2
OSVERSION=centos-7.4
ARCHITECTURE=x86_64

# start the domain and wait for it to get an IP
virsh start ${NAME}-${OSVERSION}-${ARCHITECTURE}

# get mac address of the machine
MAC=`virsh dumpxml ${NAME}-${OSVERSION}-${ARCHITECTURE} | grep 'mac address' | cut -d\' -f2`

# get the dynamic IP for the machine
printf "Waiting for domain to start to get its IP address"
counter=0
while : ; do
    IP=`virsh net-dhcp-leases default --mac ${MAC} | grep ipv4 | awk '{print $5}' | cut -d/ -f1`
    if [[ ! -z ${IP} || ${counter} -eq 30 ]]; then
        break
    else
        sleep 1
        ((counter++))
        printf "."
    fi
done

printf "\n"

# delete static IP entry
virsh net-update default delete ip-dhcp-host \
          "<host mac='${MAC}' \
           name='${HOST}' ip='${IP}' />" \
           --live --config

# remove from /etc/hosts
sudo sed -i "/${IP} ${HOST}/d" /etc/hosts

# delete domain
virsh shutdown ${NAME}-${OSVERSION}-${ARCHITECTURE}
virsh undefine ${NAME}-${OSVERSION}-${ARCHITECTURE}

# delete volume
virsh vol-delete --pool vms ${NAME}-${OSVERSION}-${ARCHITECTURE}-sda.qcow2 

