#!/bin/bash
while getopts i:u:k:g:o:r:w:u:y:s:m:d: option
    do case "${option}"
        in
    i) PIP=${OPTARG};;
    u) USER=${OPTARG};;
    k) KEY=${OPTARG};;
    g) GRIDPASS=${OPTARG};;
    o) ORACLEPASS=${OPTARG};;
    r) ROOTPASS=${OPTARG};;
    w) SWAPSIZE=${OPTARG};;
    u) STORAGEURL=${OPTARG};;
    y) SYSPASS=${OPTARG};;
    s) SYSTEMPASS=${OPTARG};;
    m) MONITORPASS=${OPTARG};;
    d) DBNAME=${OPTARG};;
        esac
        done
# Update all packages that have available updates.
sudo yum update -y

# Install Python 3 and pip.
sudo yum install -y python3-pip

# Upgrade pip3.
sudo pip3 install --upgrade pip

# Install Ansible.
pip3 install ansible[azure]

# Install Ansible modules and plugins for interacting with Azure.
ansible-galaxy collection install azure.azcollection

# Install required modules for Ansible on Azure
wget https://raw.githubusercontent.com/ansible-collections/azure/dev/requirements-azure.txt

# Install Ansible modules
sudo pip3 install -r requirements-azure.txt

ansible-playbook -i $PIP, -u $USER Configure-ASM-server.yml -e gridpass=$GRIDPASS -e oraclepass=$ORACLEPASS -e rootpass=$ROOTPASS -e swapsize=$SWAPSIZE -e gridurl=$gridurl -e syspass=$SYSPASS -e systempass=$SYSTEMPASS -e monitorpass=$MONITORPASS -e dbname=$DBNAME
