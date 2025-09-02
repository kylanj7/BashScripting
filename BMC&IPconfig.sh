ENVIRONMENT=${1:-dev}
INTERFACE=$(ls /sys/class/net/ | grep -v lo | head -1)
USERNAME="admin"

# Takes user input of the BMC and LAN IP addresses. 
read -p " Enter the servers assigned static IP address for network connectivity: " LAN_IP
echo "IP address for the local area network set to: $LAN_IP"

# Extract subnet from LAN_IP and set parameters automatically. Takes into account varying octets in subnet range
if [[ $LAN_IP == 10.*.*.* ]]; then # Class A Network
    GATEWAY="10.0.0.1"
    SUBNET="255.0.0.0"
    PRIMARY_DNS="8.8.8.8"
    SECONDARY_DNS="8.8.4.4"
    CIDR="8"
elif [[ $LAN_IP == 172.16.*.* || $LAN_IP == 172.17.*.* || $LAN_IP == 172.18.*.* ]]; then # Class B Network
    GATEWAY="172.16.0.1"
    SUBNET="255.240.0.0"
    PRIMARY_DNS="8.8.8.8"
    SECONDARY_DNS="8.8.4.4"
    CIDR="12"
elif [[ $LAN_IP == 192.168.*.* ]]; then # Class C Network
    GATEWAY="192.168.1.1"
    SUBNET="255.255.0.0"
    PRIMARY_DNS="8.8.8.8"
    SECONDARY_DNS="8.8.4.4"
    CIDR="16"
else # Public IP or unknown range
    echo "Unknown subnet for IP: $LAN_IP. Please check your parameters or contact your local administrator."
    exit 1
fi

echo "Set Static LAN & Auto-calculated lab subnet: $SUBNET"
echo "Auto-calculated lab gateway address: $GATEWAY"
echo "Pulled DNS address from internal files: $PRIMARY_DNS, $SECONDARY_DNS"
echo "Local area network"

read -p "Enter the servers assigned static IP address for baseboard management console connectivity: " BMC_IP
echo "IP address for baseboard management console set to: $BMC_IP"

#Load IPMI modules
sudo modprobe ipmi_devintf
sudo modprobe ipmi_si

# Set BMC login Credentials
sudo ipmitool user set 1 $USERNAME
sudo ipmitool user set password 1
sudo ipmitool user enable 1
sudo ipmitool user list 1
sudo ipmitool lan print 1
read -p "Press Enter to continue"

# Configure the BMC static IP address
sudo ipmitool lan set 1 ipsrc static
sudo ipmitool lan set 1 ipaddr $BMC_IP
sudo ipmitool lan set 1 netmask $SUBNET
sudo ipmitool lan set 1 defgw ipaddr $GATEWAY
sudo ipmitool lan print 1
read -p "Press Enter to continue"

read -p "Would you like to configure the local area network interface? (y/n): " AUTO_YAML

if [[ $AUTO_YAML == "y" ]]; then
    #Create netplan configuration file (Ubuntu Server Only)
    sudo touch ~/00-aabash.yaml

    echo "network:" > ~/00-aabash.yaml
    echo "  ethernets:" >> ~/00-aabash.yaml
    echo "    $INTERFACE:" >> ~/00-aabash.yaml
    echo "      addresses:" >> ~/00-aabash.yaml
    echo "        - $LAN_IP/$CIDR" >> ~/00-aabash.yaml
    echo "      routes:" >> ~/00-aabash.yaml
    echo "        - to: default" >> ~/00-aabash.yaml
    echo "          via: $GATEWAY" >> ~/00-aabash.yaml
    echo "      nameservers:" >> ~/00-aabash.yaml
    echo "        addresses: [$PRIMARY_DNS, $SECONDARY_DNS]" >> ~/00-aabash.yaml
    echo "  version: 2" >> ~/00-aabash.yaml

    sudo cp ~/00-aabash.yaml /etc/netplan/00-aabash.yaml
    sudo netplan apply

    echo "Netplan configuration applied"

    # Wait for 10 seconds so that the network interface can initialize, then initiate a ping test
    echo "Waiting for network to initialize"
    spinner='|/-\|'
    for i in {10..1}; do
        for j in {0..3}; do
            printf "\rTesting connectivity in%2d seconds... %c" $i "${spinner:$j:1}"
            sleep 0.25
        done
    done
    printf "\rTesting connectivity now...                 \n"

    # Ping the gateway to test outside communication
    if ping -c 4 $GATEWAY > /dev/null 2>&1; then
        echo "Network connection successful."
    else
        echo "Network connection failed - cannot reach gateway $GATEWAY"
        echo "Current network interfaces: "
        ip a
        echo "Check the network configuration in /etc/netplan/ directory." 
        echo "(Hint) use ethtool -p "interface name" 30 to find the interfaces physical location"
        read -p "Press Enter to continue"
        exit 1
    fi
else
    echo "Netplan configuration skipped. "
    echo "Note: You may need to manually configure settings in /etc/netplan/"

fi

read -p "Would you like to view the YAML configuration? (y/n): " VIEW_YAML

if [[ $VIEW_YAML == "y" ]]; then
    # Print the newly generated netplan config file "00-aabash.yaml"
    if [[ -f /etc/netplan/00-aabash.yaml ]]; then #-f is a file test operator that tests to see if the file exists.
        cat /etc/netplan/00-aabash.yaml
        read -p "Press Enter to continue"
    else
        echo "Configuration file not found at /etc/netplan/"
    fi
else
    echo "Skipping .yaml display"
fi



#Print the completion of the configuration script
if [[ $LAN_IP == 10.*.*.* ]]; then
    echo "Network configuration complete for subnet /$CIDR"
elif [[ $LAN_IP == 172.16.*.* || $LAN_IP == 172.17.*.* || $LAN_IP == 172.18.*.* ]]; then
    echo "Network configuration complete for subnet /$CIDR"
elif [[ $LAN_IP == 192.168.*.* ]]; then
    echo "Network configuration complete for subnet /$CIDR"
fi
