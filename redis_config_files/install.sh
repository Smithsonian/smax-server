#!/bin/bash
#
# Install, enable and run the smax-scripts.service with systemd
#
# This installer should be run as root/with sudo permissions
#
# Paul Grimes
# 04/18/2023
#
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit 1
fi

SMAX="/usr/share/smax"
LUA="/usr/share/smax/lua"

mkdir -p $SMAX
mkdir -p $LUA

cp -R "./lua" $SMAX
cp "./smax-init.sh" $SMAX
cp "./smax-scripts.service" $SMAX

chmod -R 755 $SMAX

ln -s "$SMAX/smax-scripts.service" "/etc/systemd/system/smax-scripts.service"

read -p "Configure redis for SMA-X at this time? " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    cp "./redis.conf" "/etc/"
    systemctl daemon-reload
    systemctl enable redis
    systemctl restart redis
fi

read -p "Enable smax-scripts at this time? " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    systemctl daemon-reload
    systemctl enable smax-scripts
    systemctl restart smax-scripts
fi

exit