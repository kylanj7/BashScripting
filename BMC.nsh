@echo -off
# UEFI Shell BMC Configuration Script
# Configures BMC credentials and network settings via raw IPMI commands

echo "BMC Configuration Script"
echo "========================"
echo ""

# Prompt for username
echo "Enter BMC username (default: ADMIN):"
set /p USERNAME
if "%USERNAME%" == "" then
  set USERNAME "ADMIN"
endif

# Prompt for password
echo ""
echo "Enter BMC password:"
set /p PASSWORD

# Prompt for BMC IP address
echo ""
echo "Enter BMC IP address (e.g., 192.168.1.100):"
set /p BMC_IP

# Auto-detect network configuration based on IP address
echo ""
echo "Auto-detecting network configuration..."

# Extract first octet to determine network class
set FIRST_OCTET %BMC_IP:~0,2%

# Check for Class A (10.x.x.x)
if "%FIRST_OCTET%" == "10" then
  set GATEWAY "10.0.0.1"
  set SUBNET "255.0.0.0"
  set PRIMARY_DNS "8.8.8.8"
  set SECONDARY_DNS "8.8.4.4"
  set CIDR "8"
  echo "Detected Class A network (10.0.0.0/8)"
  goto ConfigDetected
endif

# Check for Class B (172.16.x.x - 172.31.x.x)
set FIRST_THREE %BMC_IP:~0,3%
if "%FIRST_THREE%" == "172" then
  # Extract second octet (assuming format 172.XX.x.x)
  set SECOND_OCTET %BMC_IP:~4,2%
  # Check if in range 16-31
  if %SECOND_OCTET% GEQ 16 then
    if %SECOND_OCTET% LEQ 31 then
      set GATEWAY "172.16.0.1"
      set SUBNET "255.240.0.0"
      set PRIMARY_DNS "8.8.8.8"
      set SECONDARY_DNS "8.8.4.4"
      set CIDR "12"
      echo "Detected Class B network (172.16.0.0/12)"
      goto ConfigDetected
    endif
  endif
endif

# Check for Class C (192.168.x.x)
set FIRST_SEVEN %BMC_IP:~0,7%
if "%FIRST_SEVEN%" == "192.168" then
  set GATEWAY "192.168.1.1"
  set SUBNET "255.255.0.0"
  set PRIMARY_DNS "8.8.8.8"
  set SECONDARY_DNS "8.8.4.4"
  set CIDR "16"
  echo "Detected Class C network (192.168.0.0/16)"
  goto ConfigDetected
endif

# Default/Manual configuration if no match
echo "Warning: IP address doesn't match common private ranges"
echo ""
echo "Enter subnet mask manually:"
set /p SUBNET
echo "Enter gateway IP address manually:"
set /p GATEWAY
goto ConfigComplete

:ConfigDetected
echo ""
echo "Would you like to use auto-detected settings? (Y/N)"
echo "Gateway: %GATEWAY%"
echo "Subnet: %SUBNET%"
set /p AUTO_CONFIRM

if "%AUTO_CONFIRM%" == "N" goto ManualConfig
if "%AUTO_CONFIRM%" == "n" goto ManualConfig
goto ConfigComplete

:ManualConfig
echo ""
echo "Enter subnet mask:"
set /p SUBNET
echo "Enter gateway IP address:"
set /p GATEWAY

:ConfigComplete

echo ""
echo "Configuration Summary:"
echo "====================="
echo "Username: %USERNAME%"
echo "Password: ********"
echo "BMC IP: %BMC_IP%"
echo "Subnet: %SUBNET%"
echo "Gateway: %GATEWAY%"
echo ""
echo "Press Enter to apply configuration or Ctrl+C to cancel..."
pause

echo ""
echo "Applying BMC configuration..."

# Send raw IPMI commands to configure BMC
# Set username (User ID 2 - first configurable user)
IpmiSendCommand 0x06 0x45 0x02 %USERNAME%

# Set password for user ID 2
IpmiSendCommand 0x06 0x47 0x02 0x02 %PASSWORD%

# Enable user
IpmiSendCommand 0x06 0x43 0x02 0x01

# Set IP to static
IpmiSendCommand 0x0C 0x01 0x01 0x04 0x01

# Set IP address
IpmiSendCommand 0x0C 0x01 0x01 0x03 %BMC_IP%

# Set subnet mask
IpmiSendCommand 0x0C 0x01 0x01 0x06 %SUBNET%

# Set gateway
IpmiSendCommand 0x0C 0x01 0x01 0x0C %GATEWAY%

echo ""
echo "BMC configuration complete!"
echo ""
echo "You can now access BMC at: %BMC_IP%"
echo "Username: %USERNAME%"
echo ""
pause
