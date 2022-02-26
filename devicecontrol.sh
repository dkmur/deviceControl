#!/bin/bash

folder=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
exec_folder=$(pwd)

pathStats=$(grep 'pathStats' $folder/config.ini | awk '{ print $3 }')
source $pathStats/config.ini

origin=$1
action=$2
coords=$3

query(){
if [ -z "$SQL_password" ]
then
  mysql -h$DB_IP -P$DB_PORT -u$SQL_user $1 -sN -e "$2;"
else
  mysql -h$DB_IP -P$DB_PORT -u$SQL_user -p$SQL_password $1 -sN -e "$2;"
fi
}

getvariables(){
deviceid=$(query "$MAD_DB" "select device_id from settings_device where name = '$origin'") || echo "Cannot query MADdb for device_id"
instance_name=$(query "$MAD_DB" "select b.name from settings_device a, madmin_instance b where a.name = '$origin' and a.instance_id = b.instance_id") || echo "Cannot query MADdb for instance_name"
if [[ -z $deviceid || -z $instance_name ]]
then
  echo "$origin not found in database, exiting script"
  exit 1
fi
MADmin_url=$(grep -A1 "^MAD_instance_name.*$instance_name" $pathStats/config.ini | tail -1 | awk 'BEGIN { FS = "=" } ; { print $2 }')
MADmin_user=$(grep -A2 "^MAD_instance_name.*$instance_name" $pathStats/config.ini | tail -1 | awk 'BEGIN { FS = "=" } ; { print $2 }')
MADmin_pass=$(grep -A3 "^MAD_instance_name.*$instance_name" $pathStats/config.ini | tail -1 | awk 'BEGIN { FS = "=" } ; { print $2 }')
MAD_path=$(grep -A4 "^MAD_instance_name.*$instance_name" $pathStats/config.ini | tail -1 | awk 'BEGIN { FS = "=" } ; { print $2 }')
}

pauseDevice(){
getvariables
curl --silent --output /dev/null --show-error --fail -u $MADmin_user:$MADmin_pass "$MADmin_url/api/device/$deviceid" -H "Content-Type: application/json-rpc" --data-binary '{"call":"device_state","args":{"active":0}}' || { echo "Failed to pause device" ; exit 1; }
}

unpauseDevice(){
getvariables
curl --silent --output /dev/null --show-error --fail -u $MADmin_user:$MADmin_pass "$MADmin_url/api/device/$deviceid" -H "Content-Type: application/json-rpc" --data-binary '{"call":"device_state","args":{"active":1}}' || { echo "Failed to unpause device" ; exit 1; }
}

quitPogo(){
getvariables
curl --silent --output /dev/null --show-error --fail -u $MADmin_user:$MADmin_pass "$MADmin_url/quit_pogo?origin=$origin" || { echo "Failed to quit pogo" ; exit 1; }
}

startPogo(){
getvariables
curl --silent --output /dev/null --show-error --fail -u $MADmin_user:$MADmin_pass "$MADmin_url/quit_pogo?origin=$origin&restart=1" || { echo "Failed to (re)start pogo" ; exit 1; }
}

rebootDevice(){
getvariables
curl --silent --output /dev/null --show-error --fail -u $MADmin_user:$MADmin_pass "$MADmin_url/restart_phone?origin=$origin"  || { echo "Failed to reboot device" ; exit 1; }
}

logcatDevice(){
getvariables
#  filename=$(curl --silent --show-error --fail -L --head -u  $MADmin_user:$MADmin_pass "$MADmin_url/download_logcat?origin=$origin" | grep -w filename | awk 'BEGIN { FS = "=" } ; { print $2 }'
rm -f logcat_$origin.zip
curl --silent  --show-error --fail -O -J -L -u $MADmin_user:$MADmin_pass "$MADmin_url/download_logcat?origin=$origin" || { echo 'Failed to download logcat' ; exit 1; }
rm -f logcat.txt
rm -f vm.log
rm -f vmapper.log
unzip -q logcat_$origin.zip
rm -f logcat_$origin.zip
}

clearGame(){
getvariables
curl --silent --output /dev/null --show-error --fail -u $MADmin_user:$MADmin_pass "$MADmin_url/clear_game_data?origin=$origin"  || { echo "Failed to clear pogo game data" ; exit 1; }
}

screenshot(){
getvariables
curl --silent  --show-error --fail -u $MADmin_user:$MADmin_pass "$MADmin_url/take_screenshot?origin=$origin" || { echo 'Failed to refresh screen' ; exit 1; }
}

sendWorker(){
#get specific variables
device_maxDistance=$(grep "device_maxDistance" $folder/config.ini | awk '{ print $3 }')
device_waittime=$(grep "device_waittime" $folder/config.ini | awk '{ print $3 }')
device_toUse=$(grep "device_toUse" $folder/config.ini | awk '{ print $3 }')

# find device closest
coords_input=$(sed 's/,/ /g' <<< $coords)
if [[ $device_toUse == "all" ]]
then
  originDist=$(query "$MAD_DB" "select b.name, round(ST_Distance(a.currentPos,GeomFromText('POINT($coords_input)'))*111.38,0) as 'distance' from trs_status a, settings_device b where a.device_id=b.device_id and a.lastProtoDateTime > now() - interval 1 minute and idle = 0 and a.area_id in (select area_id from settings_area_mon_mitm) order by distance limit 1")
else
  originDist=$(query "$MAD_DB" "select b.name, round(ST_Distance(a.currentPos,GeomFromText('POINT($coords_input)'))*111.38,0) as 'distance' from trs_status a, settings_device b where a.device_id=b.device_id and a.lastProtoDateTime > now() - interval 1 minute and idle = 0 and FIND_IN_SET(name,'$device_toUse') and a.area_id in (select area_id from settings_area_mon_mitm) order by distance limit 1")
fi
origin=$(echo $originDist | awk '{ print $1 }')
distance=$(echo $originDist | awk '{ print $2 }')

# check max distance in km
if [[ $distance -gt $device_maxDistance ]]
then
  echo "Closest device is $origin at $distance km, sorry maximum distance is set to $device_maxDistance km, request cancelled"
  exit 1
fi

getvariables
echo curl --silent  --show-error --fail -u $MADmin_user:$MADmin_pass "$MADmin_url/send_gps?origin=$origin&coords=$coords&sleeptime=$device_waittime" || { echo 'Failed to send $origin to location $coords' ; exit 1; }
echo " : $origin was sent to $coords"
}

# checks
if [[ -z ${1+x} || -z ${2+x} ]]
then
echo "Missing input paramter(s), exiting"
exit 1
fi
if [ $2 != "pauseDevice" ] && [ $2 != "unpauseDevice" ] && [ $2 != "quitPogo" ] && [ $2 != "startPogo" ] && [ $2 != "rebootDevice" ] && [ $2 != "logcatDevice" ] && [ $2 != "clearGame" ]  && [ $2 != "cycle" ] && [ $2 != "screenshot" ] && [ $2 != "sendWorker" ]
then
echo "Invalid action, exiting"
exit 1
fi

if [ $action == "pauseDevice" ]
then
  pauseDevice
elif [ $action == "unpauseDevice" ]
then
  unpauseDevice
elif [ $action == "quitPogo" ]
then
  quitPogo
elif [ $action == "startPogo" ]
then
  startPogo
elif [ $action == "rebootDevice" ]
then
  rebootDevice
elif [ $action == "logcatDevice" ]
then
  logcatDevice
elif [ $action == "clearGame" ]
then
  clearGame
elif [ $action == "screenshot" ]
then
  screenshot
  cp $MAD_path/temp/screenshot_$origin.jpg $exec_folder/screenshot.jpg
elif [ $action == "sendWorker" ]
then
  sendWorker
elif [ $action == "cycle" ]
then
  relay_name=$(query "$STATS_DB" "select name from relay where origin = '$origin'") || echo "Cannot query STATSdb for relay_name"
  relay_port=$(query "$STATS_DB" "select port from relay where origin = '$origin'") || echo "Cannot query STATSdb for relay_port"
  echo $relay_name
  echo $relay_port
  if [[ ! -z $relay_name && ! -z $relay_port ]]
  then
    $folder/relay_poe_control.sh $relay_name $action $relay_port
  else
    echo "Relay name or port not found in table relay for $origin"
    exit 1
  fi
else
  echo "no clue anymore :P"
fi

