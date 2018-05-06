# Create Local Virtual Cluster
The following set of scripts builds an OpenShift cluster on your local machine. This was tested on Fedora 27 but may work on other distros, with some modifications. In the first step, 3 virtual machines, with CentOS7.4, will be created on the local machine using [libvirt](https://libvirt.org/) and [libguestfs](http://libguestfs.org/).

For installation instructions of libvirt/libguestfs on Fedora, see [here](https://docs.fedoraproject.org/quick-docs/en-US/getting-started-with-virtualization.html).

> Note that two steps that should be taken before starting:
> * Set the default libvirt URI: add ```export LIBVIRT_DEFAULT_URI=qemu:///system``` to ```~/.bashrc``` (don't forget to actually run that on the current terminal)
> * Add your user to the ```libvirt``` group, so that ```sudo``` is not required when invoking libvirt commands: 
> ```
> sudo usermod -a -G libvirt $USER
> ```

The script ```create-lab.sh``` should generate the 3 machines, each with 20GB of disk, 2GB RAM and 2 CPUs. One will be the clsuter's master and the other two will be nodes. The machines will be named: ```master.cluster1```, ```node1.cluster1``` and ```node2.cluster1``` accordingly. This script is calling the ```create-vm.sh <hostname> <cluster-name>``` script that actually generates a virtual machine, together with storage and networking (hostnames and IPs are updated locally in ```/etc/hosts```).
Modify this script for different ammount of disk, RAM and CPUs, but note that lower numbers may fail the OpenShift install process.

The script ```destroy-vm.sh <hostname> <cluster-name>``` could be used to cleanup a virtual machine (note that storage will also be deleted).

> The user/password on these machines is root/centos

# Install OpenShift
Once the 3 machines are running, you can use the ```openshift-lab.sh``` script to opens a tmux session with 4 windows, one local and 3 to the 3 machines.

At this point, OpenShift3.9 could be installed on the setup. The installation is using OpenShift Origin and assumes RPM based installation on CentOS7.4 machines. The process here assume that installation happens from an external box (e.g. your laptop), and not from the master node (even though this is also possible). And should be as follows:
* After machines are first created, password-less SSH connection with them needs to be established. For that, you can use the ```renew-ssh-openshift-lab.sh``` script. Note that this script also cleans up any existing ssh entries.
  * This maps to this [section](https://docs.openshift.org/3.9/install_config/install/host_preparation.html#ensuring-host-access) in the guide
  * Make sure that ```dig``` is installed on the machine used for installation (e.g. your laptop). Use: ```yum install bind-utils```
* Run the: ```openshift-base-packages.sh``` script on each host to install base packages and docker
  * This maps to these sections in the guide:
    * [Base Packages](https://docs.openshift.org/3.9/install_config/install/host_preparation.html#installing-base-packages)
    * [Docker](https://docs.openshift.org/3.9/install_config/install/host_preparation.html#installing-docker)
    * Note that this scripts are not maintained with the documentation, so, a good thing would be to make sure that they stil follow the manual steps, or just carry on the manual steps from the guide without the script
  * Note that for the install process, docker is not required on the host, just the VMs
* Optionally, use the ```openshift-lab-prerequisite.sh``` script to run the above 2 scripts on each of the 3 servers ([TODO] probably better to create an ansible playbook for that)
* Last step would be to clone the ansible playbook git repository (currently tested with tag: [openshift-ansible-3.9.14-1](https://github.com/openshift/openshift-ansible/releases/tag/openshift-ansible-3.9.14-1) only) and run the following playbooks using the ```openshift-lab.ini``` inventory file:
``` 
ansible-playbook -i openshift-lab.ini /path/to/openshift-ansible/playbooks/prerequisites.yml
ansible-playbook -i openshift-lab.ini /path/to/openshift-ansible/playbooks/deploy_cluster.yml
```
- If the lab cluster was already installed, and you want to uninstall, the uninstall script can be used:
``` 
ansible-playbook -i openshift-lab.ini /path/to/openshift-ansible/playbooks/adhoc/uninstall.yml
```
> If you want to re-image the VMs, you can use the ```destroy-vm.sh``` and then re-create using ```create-vm.sh```. Or use snapshoting of the VMs to roll back to their original state [TODO]

# Install KubeVirt
After OpenShift is installed the kubeVirt plugin can be installed as well.

When using ansible based install, kubeVirt can only be installed from one of the nodes of the clsuter (as it need the ```oc``` command and its configuration), therefore, before installation, the following steps must be taken (lets say on the master):
* Get the [inventory](https://github.com/yuvalif/openshift-local-lab/blob/master/openshift-lab.ini) file, either ```scp``` from the machine that performed the OpenShift installation, or directly from this repo
  * ```scp openshift-lab.ini root@master.cluster1:~```
* ssh to the master, and do the following on it:
  * Allow password-less SSH connection between the master and the other two nodes. This could be done manually or by using the ```renew-host-ssh.sh``` script (can ```scp``` the script there in the same way it was done for the inventory file)
  * Install git: ```yum install git```
  * Install ansible:```yum install ansible```
  * Clone the kubevirt-ansible repo: ```git clone https://github.com/kubevirt/kubevirt-ansible.git```
  * Follow the instructions [here](https://github.com/kubevirt/kubevirt-ansible/blob/master/playbooks/README.md#openshift-cluster-1), or just execute:
```
ansible-playbook -i openshift-lab.ini /path/to/kubevirt-ansible/playbooks/selinux.yml
ansible-playbook -i openshift-lab.ini /path/to/kubevirt-ansible/playbooks/kubevirt.yml -e@/path/to/kubevirt-ansible/vars/all.yml
```
