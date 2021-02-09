# Ansible and terraform scripts for deploying ceph supported oneprovider


The ansible playbook can be used apart from terraform. If you plan to use only ansible for
deploying oneprovider follow the section Ansible. If you plan to deploy oneprovider cluster
from scratch using terraform and ansible follow the section Terraform with ansible.

# Deploying with ansible

## Requirements
ansible >=2.8.4  
jinja2 >=2.10  
jmespath  

The requirements can be installed with pip:
```
sudo pip install -U Jinja2
sudo pip install jmespath
```

## Configuring
### Ansible invetory file
Copy hosts.sample and edit it:
```
cp hosts.sample hosts
vi hosts
```
Place your hostnames and ips. There are four groups:
* [mons] - monitors
* [mgrs] - managers
* [osds] - OSDs
* [ops] - oneprovider nodes

### Ansible variables
Copy group_vars/all.yml.sample and modify it accordingly:
```
cd group_vars
cp all.yml.sample all.yml
vim all.yml
```
The variables semantic is explained in the comments.
 
## Running the playbook

Run:
```
ansible-playbook -i hosts site.yml
```

# Deploying with terraform and ansible

The terraform scripts are placed in the following directories:
gcp - scripts for Google Cloud Platform

## Requirements
* terraform version >= v0.12.24
* requirements from section Ansible

## Common configuration

Note that some ansible variables set in group_vars/all.yml will be overwirtten by the terraform scripts.
* Go to the relevant terraform directiory
* Copy or rename the sample tvars file
```
cp od.tvars.sample od.tvars
```
* Edit od.tvars - place in your parameters according to the comments
* Edit group_vars/all.yml. The variables opname and subdomain will be overwitten using the values
from od.tvars, so you leave them untouched.

## Deploying oneprovider
Run terraform
```
terraform apply -var-file od.tvars
```

