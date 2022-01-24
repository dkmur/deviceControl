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

pauseDevice(){
curl --silent --output /dev/null --show-error --fail -u $MADmin_user:$MADmin_pass "$MADmin_url/api/device/$deviceid" -H "Content-Type: application/json-rpc" --data-binary '{"call":"device_state","args":{"active":0}}'  || echo "Failed to pause device" && exit 1
}

unpauseDevice(){
curl --silent --output /dev/null --show-error --fail -u $MADmin_user:$MADmin_pass "$MADmin_url/api/device/$deviceid" -H "Content-Type: application/json-rpc" --data-binary '{"call":"device_state","args":{"active":1}}'   || echo "Failed to unpause device" && exit 1
}

quitPogo(){
curl --silent --output /dev/null --show-error --fail -u $MADmin_user:$MADmin_pass "$MADmin_url/quit_pogo?origin=$origin" || echo "Failed to quit pogo" && exit 1
}

startPogo(){
curl --silent --output /dev/null --show-error --fail -u $MADmin_user:$MADmin_pass "$MADmin_url/quit_pogo?origin=$origin&restart=1" || echo "Failed to (re)start pogo" && exit 1
}

rebootDevice(){
curl --silent --output /dev/null --show-error --fail -u $MADmin_user:$MADmin_pass "$MADmin_url/restart_phone?origin=$origin"  || echo "Failed to reboot device" && exit 1
}

logcatDevice(){
# curl --silent  --show-error --fail -O -J -L -u $MADmin_user:$MADmin_pass "$MADmin_url/download_logcat?origin=$origin"  || echo "Failed download logcat" && exit 1
curl --silent  --show-error --fail -O -J -L -u $MADmin_user:$MADmin_pass "$MADmin_url/download_logcat?origin=$origin"
}

clearGame(){
curl --silent --output /dev/null --show-error --fail -u $MADmin_user:$MADmin_pass "$MADmin_url/clear_game_data?origin=$origin"  || echo "Failed to clear pogo game data" && exit 1
}

# checks
if [[ -z ${1+x} || -z ${2+x} ]]
then
echo "Missing input paramter(s), exiting"
exit 1
fi
if [ $2 != "pauseDevice" ] && [ $2 != "unpauseDevice" ] && [ $2 != "quitPogo" ] && [ $2 != "startPogo" ] && [ $2 != "rebootDevice" ] && [ $2 != "logcatDevice" ] && [ $2 != "clearGame" ]
then
echo "Invalid action, exiting"
exit 1
fi

# get variables
origin=$1
action=$2
echo "wtf2"
deviceid=$(query "$MAD_DB" "select device_id from settings_device where name = '$origin'") || echo "Cannot query MADdb for device_id"
echo "wtf3"
instance_name=$(query "$MAD_DB" "select b.name from settings_device a, madmin_instance b where a.name = '$origin' and a.instance_id = b.instance_id") || echo "Cannot query MADdb for instance_name"
echo "wtf"
MADmin_url=$(grep -A1 "^MAD_instance_name.*$instance_name" $pathStats/config.ini | tail -1 | awk 'BEGIN { FS = "=" } ; { print $2 }')
MADmin_user=$(grep -A2 "^MAD_instance_name.*$instance_name" $pathStats/config.ini | tail -1 | awk 'BEGIN { FS = "=" } ; { print $2 }')
MADmin_pass=$(grep -A3 "^MAD_instance_name.*$instance_name" $pathStats/config.ini | tail -1 | awk 'BEGIN { FS = "=" } ; { print $2 }')

echo $origin
echo $action
echo $deviceid
echo $instance_name
echo $MADmin_url
echo $MADmin_user
echo $MADmin_pass

echo "test"

if [ $action == "pauseDevice" ]
then
  pause
elif [ $action == "unpauseDevice" ]
then
  unpause
elif [ $action == "quitPogo" ]
then
  quit
elif [ $action == "startPogo" ]
then
  start
elif [ $action == "rebootDevice" ]
then
  reboot
elif [ $action == "logcatDevice" ]
then
  logcatDevice
elif [ $action == "clearGame" ]
then
  clearGame
else
  echo "no clue anymore :P"
fi

