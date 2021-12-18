#!/bin/bash
Home=$HOME
source config.ini

portnum=1
while (( $port < 49 )); do
echo ""
echo "Enabling port $port"
snmpset -v $1_version -c $1_community -u $1_username $1_ip:$1_port 1.3.6.1.2.1.105.1.1.1.3.1.$port i 2
portnum=$((portnum+1))
done
