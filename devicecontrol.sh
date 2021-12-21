#!/bin/bash

stoppoe(){
echo "snmpset -v $version -c $community -u $username $ip:$port 1.3.6.1.2.1.105.1.1.1.3.1.$action i 2"
}

startpoe(){
echo "snmpset -v $version -c $community -u $username $ip:$port 1.3.6.1.2.1.105.1.1.1.3.1.$action i 1"
}

if [[ -z ${1+x} || -z ${2+x} || -z ${3+x} ]]
then
  # ask the questions
  clear
  echo ""
  echo ""
  echo "Enter name of switch/relay to be used:"
  read device
  echo ""
  echo "Action: stop, start or (power)cycle"
  read activity
  echo ""
  echo "Enter port number or all"
  read action
  echo ""
else
  device=$1
  activity=$2
  action=$3
fi

check=$(grep $device config.ini | wc -l)
if (( $check == 0 ))
then
  echo "switch/relay not found in config.ini, please check settings"
  exit
fi

# we could check if we exceed max port/relay number of the device here and exit otherwise

# get variables
type=$(grep -A1 $device config.ini | tail -1 | awk '{ print $3 }')
ip=$(grep -A2 $device config.ini | tail -1 | awk '{ print $3 }')
port=$(grep -A3 $device config.ini | tail -1 | awk '{ print $3 }')
relays=$(grep -A4 $device config.ini | tail -1 | awk '{ print $3 }')
sleep=$(grep -A5 $device config.ini | tail -1 | awk '{ print $3 }')
if [ $type == poe ]
then
  username=$(grep -A6 $device config.ini | tail -1 | awk '{ print $3 }')
  version=$(grep -A7 $device config.ini | tail -1 | awk '{ print $3 }')
  community=$(grep -A8 $device config.ini | tail -1 | awk '{ print $3 }')
fi

# stop poe port(s)
if [[ $type == poe && $activity == stop ]]
then
  if [ $action != all ]
  then
    stoppoe
  fi
  if [ $action == all ]
  then
    action=1
    while (( $action <= $relays )); do
    echo ""
    echo "Disabling port $action"
    stoppoe
    sleep 3s
    action=$((action+1))
    done
  fi
fi
# start poe port
if [[ $type == poe && $activity == start ]]
then
  if [ $action != all ]
  then
    startpoe
  fi
  if [ $action == all ]
  then
    action=1
    while (( $action <= $relays )); do
    echo ""
    echo "Eanabling port $action"
    startpoe
    sleep $sleep
    action=$((action+1))
    done
  fi
fi
# cycle poe port
if [[ $type == poe && $activity == cycle ]]
then
  if [ $action != all ]
  then
    stoppoe
    sleep 5s
    startpoe
  fi
  if [ $action == all ]
  then
    action=1
    while (( $action <= $relays )); do
    echo ""
    echo "Power cycling port $action"
    stoppoe
    sleep 5s
    startpoe
    sleep $sleep
    action=$((action+1))
    done
  fi
fi
