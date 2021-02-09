#!/bin/bash
# Args: TODO
# Example: TODO
# Remove the hosts from .ssh/known_hosts and run a command via ssh so
# next use of ssh will not require user interaction
for f in ceph-ips.txt op-ips.txt; do
    grep ansible_host $f | cut -f2 -d' ' | cut -f2 -d= | xargs -I{} ssh-keygen -R {}
    grep ansible_host $f | cut -f2 -d' ' | cut -f2 -d= | xargs -I{} ssh -o StrictHostKeyChecking=no -l $3 {} hostname
done
# Prepare invetory file "ceph-hosts" for ansible
{
    echo "[mons]"
    head -3 ceph-ips.txt
    echo 
    echo "[mgrs]"
    head -3 ceph-ips.txt
    echo 
    echo "[osds]"
    cat ceph-ips.txt
    echo
    echo "[ops]"
    cat op-ips.txt
    echo
}>ceph-op-hosts

# Run the playbook
P=$(pwd | rev | cut -d'/' -f 1 | rev)
cd ..
#ansible-playbook -i ${P}/ceph-op-hosts ceph-prep.yml -e "opname=$1 subdomain=$2 ansible_user=$3"
echo P=${P}
cd ceph-ansible
#ansible-playbook -i ../${P}/ceph-op-hosts site.yml
cd ..
ansible-playbook -i ${P}/ceph-op-hosts ceph-after.yml
#ansible-playbook -i ${P}/ceph-op-hosts op.yml


