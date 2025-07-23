#!/bin/bash

ENVIRONMENT=${1:-dev}

GATEWAY=
PRIMARY_DNS=
SECONDARY_DNS=
NETMASK=255.255.254.0
INTERFACE=$(ls /sys/class/net/ | grep -v lo | head -1)

read -p "Enter the servers assigned static local area network IP address: " LAN_IP
echo "The servers static local area network address has been set to $LAN_IP"
read -p "Enter the servers assigned static BMC IP address: " BMC_IP
echo "The servers static BMC address has been set to $BMC_IP"

sudo ipmitool lan set 1 ipsrc static
ipmitool lan set 1 ipaddr $BMC_IP
ipmitool lan set 1 netmask $NETMASK
ipmitool lan set 1 defgw ipaddr $GATEWAY

# Create a new netplan yaml config file
sudo touch ~/00-aabash.yaml

# Apply network config to netplan yaml config file. "00-aa" ensures the file is selected 1st alphabetically. 
echo "network:" > ~/00-aabash.yaml
echo "  ethernets:" >> ~/00-aabash.yaml
echo "    $INTERFACE:" >> ~/00-aabash.yaml
echo "      dhcp4: false" >> ~/00-aabash.yaml
echo "      addresses:" >> ~/00-aabash.yaml
echo "        - $LAN_IP/23" >> ~/00-aabash.yaml
echo "      routes:" >> ~/00-aabash.yaml
echo "        - to: default" >> ~/00-aabash.yaml
echo "          via: $GATEWAY" >> ~/00-aabash.yaml
echo "      nameservers:" >> ~/00-aabash.yaml
echo "        addresses: [$PRIMARY_DNS, $SECONDARY_DNS,]" >> ~/00-aabash.yaml
echo "  version: 2" >> ~/00-aabash.yaml
 
#Copy the custom config to the netplan folder and apply
sudo cp ~/00-aabash.yaml /etc/netplan/00-aabash.yaml

#Apply the new netplan config
sudo netplan apply
