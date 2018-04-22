#!/bin/bash

yum -y install wget git net-tools bind-utils iptables-services bridge-utils bash-completion kexec-tools sos psacct
yum -y update
# prepare for RPM based install
yum -y install atomic-openshift-utils

# install docker
yum -y install docker

# TODO: configure docker storage

# enable and start docker
systemctl enable docker
systemctl start docker


