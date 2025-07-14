#! /usr/bin/env bash
 
#For use with Ubuntu Server. Assumes Ubuntu Cloud image and default sudo account. 
#This script is meant to run with sudo.  
#sudo bash ~/host_deploy.sh 

#!/bin/bash

GATEWAY_ADDRESS= 
PRIMARY_DNS_ADDRESS=
SECONDARY_DNS_ADDRESS=

ipmitool lan set 1 ipsrc static 
ipmitool lan set 1 ipaddr 
ipmitool lan set 1 netmask 
ipmitool lan set 1 defgw ipaddr 

#Gather input from userits a work in progress
read -p "Type the IP address in CIDR notation, i.e. 192.168.1.1/24: " IP_ADDRESS 
#read -p "The gateway IP: " GATEWAY_ADDRESS 
#read -p "The primary DNS IP: " PRIMARY_DNS_ADDRESS 
#read -p "And finally, the secondary DNS IP: " SECONDARY_DNS_ADDRESS 

# Create a new netplan yaml config file 
sudo touch ~/99-custom.yaml 

# Apply network config to netplan yaml config file 
# Making some assumptions here about the adapter name 
echo "network:" > ~/99-custom.yaml 
echo "  ethernets:" >> ~/99-custom.yaml 
echo "    enp0s31f6:" >> ~/99-custom.yaml 
echo "      dhcp4: false" >> ~/99-custom.yaml
echo "      addresses:" >> ~/99-custom.yaml
echo "       - [$IP_ADDRESS]" >> ~/99-custom.yaml
echo "      routes:" >> ~/99-custom.yaml
echo "       - to: default" >> ~/99-custom.yaml
echo "         via: $GATEWAY_ADDRESS" >> ~/99-custom.yaml
echo "      nameservers:" >> ~/99-custom.yaml
echo "        addresses: [$PRIMARY_DNS_ADDRESS, $SECONDARY_DNS_ADDRESS, 10.248.2.1, 10.45.15.7]" >> ~/99-custom.yaml
echo "  version: 2" >> ~/99-custom.yaml

#Copy the custom config to the netplan folder and apply
sudo cp ~/99-custom.yaml /etc/netplan/99-custom.yaml

#Apply the new config
sudo netplan apply
