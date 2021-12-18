#!/bin/bash

source config.ini

function View
{
clear
routine1=0

while [[ $routine != "1" ]]
do
echo ""
echo "                          SELECT OPTION FROM BELOW  "
echo ""
echo ""
echo "                                    1 = Power cycle port"
echo ""
echo "                                    2 = Power down port"
echo ""
echo "                                    3 = Power up port"
echo ""
echo ""
echo ""
echo "                                    10 = Power cycle all"
echo ""
echo "                                    11 = Power down all"
echo ""
echo "                                    12 = Power up all"
echo ""
echo ""
echo ""
echo "                                    q = QUIT "
echo ""
echo ""

date '+%m%d%y_%H%M' | read -r AUTODATE

read opt
echo $USER $AUTODATE $opt >> log.txt

clear

# echo ""

case $opt in

        q)      echo""
                routine=1
                exit
                ;;
         1)     $path_to_deviceControl/progs/port_cycle.sh
                ;;
         2)     $path_to_deviceControl/progs/port_stop.sh
                ;;
         3)     $path_to_deviceControl/progs/port_start.sh
                ;;
         10)    $path_to_deviceControl/progs/all_cycle.sh
                ;;
esac
# echo ""
echo "                          Press ENTER to return to main menu"
read hold
clear
done
clear
}

View
