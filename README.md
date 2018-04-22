# Create Virtual Cluster
The following set of scripts build an Openshift cluster on your local machine. This was tested on Fedora 27 but may work on other distros, with some modifications. In the first step, 3 virtual machines will be created on the local machine using [libvirt](https://libvirt.org/).

For installation instructions of libvirt on Fedora, see [here](https://docs.fedoraproject.org/quick-docs/en-US/getting-started-with-virtualization.html).

The script ```create-lab.sh``` should generate the 3 CentOS7.4 machines, each with 20GB of disk, 2GB RAM and 2 CPUs. One will be the clsuter's master and the other two will be nodes. The machines will be named: ```master.cluster1```, ```node1.cluster1``` and ```node2.cluster1```. This will be calling the ```create-vm.sh <hostname> <cluster-name>``` script that generates the virtual machine, modify this script for different ammount of disk, and and CPUs, but note that lower numbers may fail the Openshift install process.

The script ```destroy-vm.sh <hostname> <cluster-name>``` could be used to cleanup a virtual machine (note that storage will also be deleted).

# Install Openshift
Once the 3 machines are running, you can use the ```openshift-lab.sh``` script to opens a tmux session with 4 windows, one local and 3 to the 3 machines. 

At this Openshift3.9 could be installed on the setup. The installation is using Openshift Origin and assumes RPM based installation on CentOS7.4 machines.
The process should be as follows:
 - After machines are first created, password-less SSH connection with them needs to be established. For that, use the ```renew-ssh-openshift-lab.sh``` script. Note that this script also cleans up any existing ssh entries.
  - This maps to this section: https://docs.openshift.org/3.9/install_config/install/host_preparation.html#ensuring-host-access in the guide
 - Run the: ```openshift-base-packages.sh``` script on each host to install base packages and docker
  - This maps to these sections in the guide:
   - https://docs.openshift.org/3.9/install_config/install/host_preparation.html#installing-base-packages
   - https://docs.openshift.org/3.9/install_config/install/host_preparation.html#installing-docker 
 - Optionally, use the ```openshift-lab-prerequisite.sh``` script to run the above 2 scripts on each of the 3 servers (probably better to create an ansible playbook for that)
 - Last step would be to clone the ansible playbook git repository (currently tested with tag: [openshift-ansible-3.9.14-1](https://github.com/openshift/openshift-ansible/releases/tag/openshift-ansible-3.9.14-1) only) and run the following playbooks using the ```openshift-lab.ini``` inventory file:
``` 
ansible-playbook -i openshift-lab.ini /path/to/openshift-ansible/playbooks/prerequisites.yml
ansible-playbook -i openshift-lab.ini /path/to/openshift-ansible/playbooks/deploy_cluster.yml
```
 - If the lab cluster was already installed, the uninstall script can be used in most cases (note that in some error cases re-imaging will be required - the ```destroy-vm.sh``` and ```create-vm.sh``` could be used for that):
``` 
ansible-playbook -i openshift-lab.ini /path/to/openshift-ansible/playbooks/adhoc/uninstall.yml
```

# Install Kubevirt
After Openshift is installed the kubevirt plugin can be installed as well.

When using ansible based install, kubevirt can only be installed from one of the nodes of the clsuter (as it need the ```oc``` command and its configuration), therefore, before installation, the following steps must be taken (lets say on the master):
 - Get the [inventory](https://gitlab.cee.redhat.com/ylifshit/openshift-e2e-lab/blob/master/openshift-lab.ini) file, either ```scp``` from the machine that performed the Openshift installation, or directly from this repo
  - ```scp openshift-lab.ini root@master.cluster1:~```
 - ssh to the master, and do the following on it:
  - Allow password-less SSH connection between the master and the other two nodes. This could be done manually or by using the ```renew-host-ssh.sh``` script (can ```scp``` the script there in the same way it was done for the inventory file)
  - Install git: ```yum install git```
  - Install ansible:```yum install ansible```
  - Clone the kubevirt-ansible repo: ```git clone https://github.com/kubevirt/kubevirt-ansible.git```
  - Follow the instructions [here](https://github.com/kubevirt/kubevirt-ansible/blob/master/playbooks/README.md#openshift-cluster-1), or just execute:
```
ansible-playbook -i openshift-lab.ini /path/to/kubevirt-ansible/playbooks/selinux.yml
ansible-playbook -i openshift-lab.ini /path/to/kubevirt-ansible/playbooks/kubevirt.yml -e@/path/to/kubevirt-ansible/vars/all.yml
```
