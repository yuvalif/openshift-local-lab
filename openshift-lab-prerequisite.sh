#!/bin/bash

ssh root@master.cluster1 "bash -s" < openshift-base-packages.sh
ssh root@node1.cluster1 "bash -s" < openshift-base-packages.sh
ssh root@node2.cluster1 "bash -s" < openshift-base-packages.sh

