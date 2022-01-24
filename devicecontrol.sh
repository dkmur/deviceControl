#!/bin/bash

folder=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

#source $folder/config.ini
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

pause(){
curl --silent --output /dev/null --show-error --fail -u $MADmin_user:$MADmin_pass "$MADmin_url/api/device/$deviceid" -H "Content-Type: application/json-rpc" --data-binary '{"call":"device_state","args":{"active":0}}'
}

unpause(){
curl --silent --output /dev/null --show-error --fail -u $MADmin_user:$MADmin_pass "$MADmin_url/api/device/$deviceid" -H "Content-Type: application/json-rpc" --data-binary '{"call":"device_state","args":{"active":1}}'
}

quit(){
curl --silent --output /dev/null --show-error --fail -u $MADmin_user:$MADmin_pass "$MADmin_url/quit_pogo?origin=$origin&adb=False"
}

start(){
curl --silent --output /dev/null --show-error --fail -u $MADmin_user:$MADmin_pass "$MADmin_url/quit_pogo?origin=$origin&restart=1"
}

reboot(){
curl --silent --output /dev/null --show-error --fail -u $MADmin_user:$MADmin_pass "$MADmin_url/restart_phone?origin=$origin"
}

# checks
if [[ -z ${1+x} || -z ${2+x} ]]
then
echo "Missing input paramter(s), exiting"
exit 1
fi
if [ $2 != "pause" ] && [ $2 != "unpause" ] && [ $2 != "quit" ] && [ $2 != "start" ] && [ $2 != "reboot" ]
then
echo "Invalid action, exiting"
exit 1
fi

# get variables
origin=$1
action=$2
deviceid=$(query "$MAD_DB" "select device_id from settings_device where name = '$origin'")
instance_name=$(query "$MAD_DB" "select b.name from settings_device a, madmin_instance b where a.name = '$origin' and a.instance_id = b.instance_id")
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

if [ $action == "pause" ]
then
  pause
elif [ $action == "unpause" ]
then
  unpause
elif [ $action == "quit" ]
then
  quit
elif [ $action == "start" ]
then
  start
elif [ $action == "reboot" ]
then
  reboot
else
  echo "no clue anymore :P"
fi

