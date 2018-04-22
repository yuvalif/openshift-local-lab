#!/bin/bash

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <hostname> <cluster-name>"
    exit 1
fi

NAME=$1
CLUSTER=$2
HOST=$1.$2
OSVERSION=centos-7.4
OSVARIANT=centos7.0
ARCHITECTURE=x86_64
DISK_SIZE=20G
CPUS=2
RAM=2048

# build an image file and store into a local "vms" pool
virt-builder ${OSVERSION} -o ~/vms/${NAME}-${OSVERSION}-${ARCHITECTURE}-sda.qcow2 \
    --no-network --format qcow2 --arch ${ARCHITECTURE} --size ${DISK_SIZE} --root-password=password:centos \
    --hostname ${HOST}

if [ ! $? -eq 0 ]; then
    exit 1
fi

# refresh the pool
virsh pool-refresh vms

if [ ! $? -eq 0 ]; then
    exit 1
fi

# installl CentOS7.4 in that image
# "hostpassthrough is defined so that nested VMs will be supported
# "import" option to bypass actuall install
# "extra-args" to allocate static IP
virt-install -n ${NAME}-${OSVERSION}-${ARCHITECTURE} --vcpus ${CPUS} --cpu host-passthrough,cache.mode=passthrough \
    --arch ${ARCHITECTURE} --memory ${RAM} --import --os-variant ${OSVARIANT} --controller scsi,model=virtio-scsi \
    --disk vol=vms/${NAME}-${OSVERSION}-${ARCHITECTURE}-sda.qcow2,device=disk,bus=scsi,discard=unmap \
    --network network=default,model=virtio \
    --graphics spice --channel unix,name=org.qemu.guest_agent.0 --noautoconsole --noreboot

if [ ! $? -eq 0 ]; then
    exit 1
fi

# start the domain and wait for it to get an IP
virsh start ${NAME}-${OSVERSION}-${ARCHITECTURE}

# get mac address of the machine
MAC=`virsh dumpxml ${NAME}-${OSVERSION}-${ARCHITECTURE} | grep 'mac address' | cut -d\' -f2`

# get the dynamic IP for the machine
printf "Waiting for domain to start to get its IP address"
while : ; do
    IP=`virsh net-dhcp-leases default --mac ${MAC} | grep ipv4 | awk '{print $5}' | cut -d/ -f1`
    if [[ ! -z ${IP} ]]; then
        break
    else
        sleep 1
        printf "."
    fi
done

printf "\n"

# set it as a static IP, so net time it will use the same IP
virsh net-update default add ip-dhcp-host \
          "<host mac='${MAC}' \
           name='${HOST}' ip='${IP}' />" \
           --live --config

if [ ! $? -eq 0 ]; then
    exit 1
fi

# update /etc/hosts
sudo su -c "echo ${IP} ${HOST} >> /etc/hosts"

