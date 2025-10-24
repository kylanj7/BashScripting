
@echo -off
echo BMC Configuration Script
echo =====================
ipmi20.efi user set name 2 admin
stall 1000000
ipmi20.efi lan set 1 ipsrc static
stall 1000000
ipmi20.efi lan set 1 ipaddr 10.0.0.2
stall 1000000
ipmi20.efi lan set 1 netmask 255.255.255.0
stall 1000000
ipmi20.efi lan set 1 defgw ipaddr 10.0.0.1
stall 1000000
echo.
echo Configuration complete. Verifying...
ipmi20.efi lan print 1
