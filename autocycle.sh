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

# get auto cycle variables
noProtoMinutes=$(grep noProtoMinutes $folder/config.ini | awk '{ print $3 }')
noRestartMinutes=$(grep noRestartMinutes $folder/config.ini | awk '{ print $3 }')
noRebootMinutes=$(grep noRebootMinutes $folder/config.ini | awk '{ print $3 }')
minWaitMinutes=$(grep minWaitMinutes $folder/config.ini | awk '{ print $3 }')
maxPortCycle=$(grep maxPortCycle $folder/config.ini | awk '{ print $3 }')
webhook=$(grep webhook_maxPort $folder/config.ini | awk '{ print $3 }')

# just the troublemakers
troublemakers=$(query "$MAD_DB" "select count(a.device_id) from trs_status a where a.idle = 0 and a.lastProtoDateTime < now() - interval '$noProtoMinutes' minute and a.lastPogoRestart < now() - interval '$noRestartMinutes' minute and a.lastPogoReboot < now() - interval '$noRebootMinutes' minute")
#troublemakers=10
#echo $troublemakers

# check on max to cycle
if [ $troublemakers -gt $maxPortCycle  ]
then
  echo "Troublemakers ($troublemakers) exceed maxPortCycle ($maxPortCycle) as set in config.ini, exiting script" >> $folder/testing.log
  $pathStats/default_files/discord.sh --username "Autocycle failure" --color "16711680" --avatar "https://i.imgur.com/Y8jxfb9.png" --webhook-url "$webhook" --description "deviceControl autocycle script exit, too many devices require autocycling"
  exit 1
fi

# lets cycle them
while read -r line ;do
origin=$(echo $line | awk '{print $1}')
relay_name=$(echo $line | awk '{print $2}')
relay_port=$(echo $line | awk '{print $3}')

#testing + add max exit to log for now
#if [ ! -f $folder/testing.log ]
#then
#touch $folder/testing.log
#echo "Report_time       Origin        last_proto              last_pogo_restart       last_device_reboot " >>  $folder/testing.log
#fi

data=$(query "$MAD_DB" "select b.name, lastProtoDateTime, lastPogoRestart, lastPogoReboot from trs_status a, settings_device b where a.device_id = b.device_id and b.name = '$origin'")
now=$(date '+%Y%m%d %H:%M:%S')
# echo "$now $data"
# echo "$now $data" >> $folder/testing.log

# original
echo "cycling $origin"
$folder/relay_poe_control.sh $relay_name cycle $relay_port
sleep 2s

done < <(query "$MAD_DB" "select b.name, c.name, c.port from trs_status a, settings_device b, $STATS_DB.relay c where a.device_id = b.device_id and b.name = c.origin and a.idle = 0 and c.lastCycle < now() - interval '$minWaitMinutes' minute and a.lastProtoDateTime < now() - interval '$noProtoMinutes' minute and a.lastPogoRestart < now() - interval '$noRestartMinutes' minute and a.lastPogoReboot < now() - interval '$noRebootMinutes' minute")

