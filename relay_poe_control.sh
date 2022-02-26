#!/bin/bash

folder=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

pathStats=$(grep 'pathStats' $folder/config.ini | awk '{ print $3 }')
source $pathStats/config.ini

query(){
if [ -z "$SQL_password" ]
then
  mysql -h$DB_IP -P$DB_PORT -u$SQL_user $1 -sN -e "$2;"
else
  mysql -h$DB_IP -P$DB_PORT -u$SQL_user -p$SQL_password $1 -sN -e "$2;"
fi
}

stoppoe(){
if [ $useSSH == true ]
then
#  echo 'ssh -p $ssh_port $ssh_user@$ssh_ip "snmpset -v $version -c $community $ip:$port 1.3.6.1.2.1.105.1.1.1.3.1.$action i 2"'
  ssh -p $ssh_port $ssh_user@$ssh_ip "snmpset -v $version -c $community $ip:$port 1.3.6.1.2.1.105.1.1.1.3.1.$action i 2"
else
#  echo "snmpset -v $version -c $community $ip:$port 1.3.6.1.2.1.105.1.1.1.3.1.$action i 2"
  snmpset -v $version -c $community $ip:$port 1.3.6.1.2.1.105.1.1.1.3.1.$action i 2
fi
timing=$(date '+%Y%m%d %H:%M:%S')
echo "[$timing] Stop port $action on $device" >> $folder/log.txt
}

startpoe(){
if [ $useSSH == true ]
then
#  echo 'ssh -p $ssh_port $ssh_user@$ssh_ip "snmpset -v $version -c $community $ip:$port 1.3.6.1.2.1.105.1.1.1.3.1.$action i 1"'
  ssh -p $ssh_port $ssh_user@$ssh_ip "snmpset -v $version -c $community $ip:$port 1.3.6.1.2.1.105.1.1.1.3.1.$action i 1"
else
#  echo "snmpset -v $version -c $community $ip:$port 1.3.6.1.2.1.105.1.1.1.3.1.$action i 1"
  snmpset -v $version -c $community $ip:$port 1.3.6.1.2.1.105.1.1.1.3.1.$action i 1
fi
timing=$(date '+%Y%m%d %H:%M:%S')
echo "[$timing] Start port $action on $device" >> $folder/log.txt
}

stophilink(){
adjusted_action=$((action-1))
if [ $relaytype == no ]
then
setrelay=off
else
setrelay=on
fi
cd $folder && ./relaytoggle.sh $adjusted_action $setrelay $ip $port
timing=$(date '+%Y%m%d %H:%M:%S')
echo "[$timing] Stop port $action on $device" >> $folder/log.txt
}

starthilink(){
adjusted_action=$((action-1))
if [ $relaytype == no ]
then
setrelay=on
else
setrelay=off
fi
cd $folder && ./relaytoggle.sh $adjusted_action $setrelay $ip $port
timing=$(date '+%Y%m%d %H:%M:%S')
echo "[$timing] Start port $action on $device" >> $folder/log.txt
}

if [[ -z ${1+x} || -z ${2+x} || -z ${3+x} ]]
then
  # ask the questions
  devices=$(cat $folder/config.ini | grep '\[' | awk '{print $1}' | paste -s -d, - | tr '[' ' ' | tr ']' ' ')
  echo "Enter name of switch/relay to be used ($devices):"
  read device
  echo ""
  echo "Action: status, stop, start or (power)cycle"
  read activity
  echo ""
  if [[ $activity != status ]]
  then
  relays=$(grep -A4 '\[' $folder/config.ini | grep -A4 $device | tail -1 | awk '{ print $3 }')
  echo "Enter port number (from 1 to $relays) or all"
  read action
  echo ""
  fi
else
  device=$1
  activity=$2
  action=$3
fi


# get variables
type=$(grep -A1 '\[' $folder/config.ini | grep -A1 $device | tail -1 | awk '{ print $3 }')
ip=$(grep -A2 '\[' $folder/config.ini | grep -A2 $device | tail -1 | awk '{ print $3 }')
port=$(grep -A3 '\[' $folder/config.ini | grep -A3 $device | tail -1 | awk '{ print $3 }')
relays=$(grep -A4 '\[' $folder/config.ini | grep -A4 $device | tail -1 | awk '{ print $3 }')
sleep=$(grep -A5 '\[' $folder/config.ini | grep -A5 $device | tail -1 | awk '{ print $3 }')
if [ $type == hilink ]
then
  relaytype=$(grep -A6 '\[' $folder/config.ini | grep -A6 $device | tail -1 | awk '{ print $3 }')
fi
if [ $type == poe ]
then
  version=$(grep -A7 '\[' $folder/config.ini | grep -A7 $device | tail -1 | awk '{ print $3 }')
  community=$(grep -A8 '\[' $folder/config.ini | grep -A8 $device | tail -1 | awk '{ print $3 }')
fi
useSSH=$(grep 'useSSH' $folder/config.ini | awk '{ print $3 }')
if [ $useSSH == true ]
then
  ssh_user=$(grep 'ssh_user' $folder/config.ini | awk '{ print $3 }')
  ssh_ip=$(grep 'ssh_ip' $folder/config.ini | awk '{ print $3 }')
  ssh_port=$(grep 'ssh_port' $folder/config.ini | awk '{ print $3 }')
fi


# checks
check=$(grep '\[' $folder/config.ini | grep $device | wc -l)
if (( $check == 0 ))
then
  echo "$device not found in $folder/config.ini, check settings"
  exit 1
fi

if [[ $relays -lt $action ]]
then
  echo "$device has $relays ports available, $activity on relay $action is not possible"
  exit 1
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
    query "$STATS_DB" "update relay set lastCycle = now(), totCycle = totCycle+1 where name = '$device' and port = '$action'"
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
    query "$STATS_DB" "update relay set lastCycle = now(), totCycle = totCycle+1 where name = '$device' and port = '$action'"
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
    query "$STATS_DB" "update relay set lastCycle = now(), totCycle = totCycle+1 where name = '$device' and port = '$action'"
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
    query "$STATS_DB" "update relay set lastCycle = now(), totCycle = totCycle+1 where name = '$device' and port = '$action'"
    echo "wait till next port $sleep"
    sleep $sleep
    action=$((action+1))
    done
  fi
fi

# status hilink ports
if [[ $type == hilink && $activity == status ]]
then
 cd $folder && ./relaystatus.sh $ip $port
timing=$(date '+%Y%m%d %H:%M:%S')
echo "[$timing] Status request on $device" >> $folder/log.txt
fi

# status poe ports
if [[ $type == poe && $activity == status ]]
then
  if [ $useSSH == true ]
  then
    ssh -p $ssh_port $ssh_user@$ssh_ip "snmpwalk -v $version -c $community $ip:$port 1.3.6.1.2.1.105.1.3.1.1.4 | sed 's/iso.3.6.1.2.1.105.1.3.1.1.4.1 = Gauge32:/PoE power consumption:/g' | sed 's/$/ W/'"
  else
    snmpwalk -v $version -c $community $ip:$port 1.3.6.1.2.1.105.1.3.1.1.4 | sed "s/iso.3.6.1.2.1.105.1.3.1.1.4.1 = Gauge32:/PoE power consumption:/g" | sed "s/$/ W/"
  fi
echo ""
echo "Port status"
  if [ $useSSH == true ]
  then
    ssh -p $ssh_port $ssh_user@$ssh_ip "snmpwalk -v $version -c $community $ip:$port 1.3.6.1.2.1.2.2.1.8 | head -$relays | sed 's/INTEGER: 1/on/g' | sed 's/INTEGER: 2/off/g' | sed 's/iso.3.6.1.2.1.2.2.1.8./#/g'"
  else
    snmpwalk -v $version -c $community $ip:$port 1.3.6.1.2.1.2.2.1.8 | head -$relays | sed "s/INTEGER: 1/on/g" | sed "s/INTEGER: 2/off/g" | sed "s/iso.3.6.1.2.1.2.2.1.8./#/g"
  fi
timing=$(date '+%Y%m%d %H:%M:%S')
echo "[$timing] Status request on $device" >> $folder/log.txt
fi
