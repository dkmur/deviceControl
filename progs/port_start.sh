#!/bin/bash
Home=$HOME
source config.ini

echo "Enter port number"
read port

echo ""
echo "Disabling port $port"
snmpset -v $version -c $community -u $username $switch_ip:$switch_port 1.3.6.1.2.1.105.1.1.1.3.1.$port i 1
