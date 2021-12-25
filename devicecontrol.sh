#!/bin/bash

stoppoe(){
echo "snmpset -v $version -c $community -u $username $ip:$port 1.3.6.1.2.1.105.1.1.1.3.1.$action i 2"
timing=$(date '+%Y%m%d %H:%M:%S')
echo "[$timing] Stop port $action on $device" >> log.txt
}

startpoe(){
echo "snmpset -v $version -c $community -u $username $ip:$port 1.3.6.1.2.1.105.1.1.1.3.1.$action i 1"
timing=$(date '+%Y%m%d %H:%M:%S')
echo "[$timing] Start port $action on $device" >> log.txt
}

stophilink(){
adjusted_action=$((action-1))
if [ $relaytype == no ]
then
setrelay=off
else
setrelay=on
fi
echo "./relaytoggle.sh $adjusted_action $setrelay $ip $port"
timing=$(date '+%Y%m%d %H:%M:%S')
echo "[$timing] Start port $action on $device" >> log.txt
}

starthilink(){
adjusted_action=$((action-1))
if [ $relaytype == no ]
then
setrelay=on
else
setrelay=off
fi
echo "./relaytoggle.sh $adjusted_action $setrelay $ip $port"
timing=$(date '+%Y%m%d %H:%M:%S')
echo "[$timing] Start port $action on $device" >> log.txt
}

if [[ -z ${1+x} || -z ${2+x} || -z ${3+x} ]]
then
  # ask the questions
  devices=$(cat config.ini | grep '\[' | awk '{print $1}' | paste -s -d, - | tr '[' ' ' | tr ']' ' ')
  echo "Enter name of switch/relay to be used ($devices):"
  read device
  echo ""
  echo "Action: status, stop, start or (power)cycle"
  read activity
  echo ""
  if [[ $activity != status ]]
  then
  relays=$(grep -A4 '\[' config.ini | grep -A4 $device | tail -1 | awk '{ print $3 }')
  echo "Enter port number (from 1 to $relays) or all"
  read action
  echo ""
  fi
else
  device=$1
  activity=$2
  action=$3
fi

check=$(grep '\[' config.ini | grep $device | wc -l)
if (( $check == 0 ))
then
  echo "switch/relay not found in config.ini, please check settings"
  exit
fi

# we could check if we exceed max port/relay number of the device here and exit otherwise

# get variables
type=$(grep -A1 '\[' config.ini | grep -A1 $device | tail -1 | awk '{ print $3 }')
ip=$(grep -A2 '\[' config.ini | grep -A2 $device | tail -1 | awk '{ print $3 }')
port=$(grep -A3 '\[' config.ini | grep -A3 $device | tail -1 | awk '{ print $3 }')
relays=$(grep -A4 '\[' config.ini | grep -A4 $device | tail -1 | awk '{ print $3 }')
sleep=$(grep -A5 '\[' config.ini | grep -A5 $device | tail -1 | awk '{ print $3 }')
if [ $type == hilink ]
then
  relaytype=$(grep -A6 '\[' config.ini | grep -A6 $device | tail -1 | awk '{ print $3 }')
fi
if [ $type == poe ]
then
  username=$(grep -A7 '\[' config.ini | grep -A7 $device | tail -1 | awk '{ print $3 }')
  version=$(grep -A8 '\[' config.ini | grep -A8 $device | tail -1 | awk '{ print $3 }')
  community=$(grep -A9 '\[' config.ini | grep -A9 $device | tail -1 | awk '{ print $3 }')
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
    echo "Enabling port $action"
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
    echo "wait till next port $sleep"
    sleep $sleep
    action=$((action+1))
    done
  fi
fi

# stop hilink port(s)
if [[ $type == hilink && $activity == stop ]]
then
  if [ $action != all ]
  then
    stophilink
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
# start hilink port
if [[ $type == hilink && $activity == start ]]
then
  if [ $action != all ]
  then
    starthilink
  fi
  if [ $action == all ]
  then
    action=1
    while (( $action <= $relays )); do
    echo ""
    echo "Enabling port $action"
    startpoe
    sleep $sleep
    action=$((action+1))
    done
  fi
fi
# cycle hilink port
if [[ $type == hilink && $activity == cycle ]]
then
  if [ $action != all ]
  then
    stophilink
    sleep 5s
    starthilink
  fi
  if [ $action == all ]
  then
    action=1
    while (( $action <= $relays )); do
    echo ""
    echo "Power cycling port $action"
    stophilink
    sleep 5s
    starthilink
    echo "wait till next port $sleep"
    sleep $sleep
    action=$((action+1))
    done
  fi
fi

# status hilink ports
if [[ $type == hilink && $activity == status ]]
then
./relaystatus.sh $ip $port
timing=$(date '+%Y%m%d %H:%M:%S')
echo "[$timing] Status request on $device" >> log.txt
fi

# status poe ports
if [[ $type == poe && $activity == status ]]
then
snmpwalk -v $version -c $community -u $username $ip:$port 1.3.6.1.2.1.105.1.3.1.1.4 | sed "s/iso.3.6.1.2.1.105.1.3.1.1.4.1 = Gauge32:/PoE power consumption:/g" | sed "s/$/ W/"
echo ""
echo "Port status"
snmpwalk -v $version -c $community -u $username $ip:$port 1.3.6.1.2.1.2.2.1.8 | head -$relays | sed "s/INTEGER: 1/on/g" | sed "s/INTEGER: 2/off/g" | sed "s/iso.3.6.1.2.1.2.2.1.8./#/g"
timing=$(date '+%Y%m%d %H:%M:%S')
echo "[$timing] Status request on $device" >> log.txt
fi
