#!/bin/bash
#
# Install, enable and run the smax-scripts.service with systemd
#
# This installer should be run as root/with sudo permissions
#
# Paul Grimes
# 04/18/2023
# 
# Attila Kovacs
# 09/14/2024
#

if [ $EUID -ne 0 ] ; then 
  echo "Please run as root"
  exit 1
fi

if [ "$DESTDIR" == "" ] ; then
  DESTDIR="/usr"
fi

# Create /usr/share/smax and its lua/ sub-directory
SMAX="$DESTDIR/share/smax"

# Copy LUA script over to /usr/share/smax
echo ". Creating $SMAX/lua directory"
mkdir -p $SMAX/lua || exit 2

echo ". Copying LUA scripts to $SMAX/lua"
install -m 644 -D lua/* $SMAX/lua/ || exit 3

# install script loader and systemd unit file
echo ". Copying script loader to $DESTDIR/bin"
install -m 755 smax-init.sh $DESTDIR/bin/ || echo  exit 4

echo ". Setting DESTDIR in script loader"
sed -i "s:/usr:$DESTDIR:g" $DESTDIR/bin/smax-init.sh || exit 5

echo ". Copying script loader to /etc/systemd/system"
install -m 644 smax-scripts.service /etc/systemd/system/ || exit 6

echo ". Setting DESTDIR in systemd unit"
sed -i "s:/usr:$DESTDIR:g" /etc/systemd/system/smax-scripts.service || exit 7

# Register smax-scripts with systemd
echo ". Reloading systemd daemon"
systemctl daemon-reload || exit 8

# On some distros the service is redis, on others is redis-server...
REDIS=redis
if [ ! -e /lib/systemd/system/$REDIS ] ; then
  REDIS=redis-server
fi

# if you call the script with a single argument 'auto', then it will install 
# a default without asking any questions. (Without the option, the installer
# will ask you to make some choices.)
if [ "$1" == "auto" ] ; then
  # automatic installation
  echo "Automatic installation..." 

  echo ". Removing SMA-specific sections from scripts"
  sed -i '/^.*BEGIN SMA.*/,/^.*END SMA.*/d' $SMAX/lua/*.lua || exit 9
  
  echo ". Starting smax-scripts service"
  systemctl restart smax-scripts || exit 10
  
  echo ". Enabling Redis at boot"
  systemctl enable $REDIS || exit 11
  
  echo ". Enabling SMA-X at boot"
  systemctl enable smax-scripts || exit 12
else
  # prompt for choices
  echo "Manual installation..." 

  read -p "Are you going to use SMA-X outside of the SMA? " -n 1 -r
  echo    # (optional) move to a new line
  if [[ $REPLY =~ ^[Yy]$ ]] ; then 
    echo ". Removing SMA-specific sections from scripts"
    sed -i '/^.*BEGIN SMA.*/,/^.*END SMA.*$/d' *.lua || exit 13
  fi

  read -p "start redis with SMA-X scripts at this time? " -n 1 -r
  echo    # (optional) move to a new line
  if [[ $REPLY =~ ^[Yy]$ ]] ; then
    echo ". Starting smax-scripts service"
    systemctl restart smax-scripts || exit 14
  fi
  
  read -p "Enable and start SMA-X at boot time? " -n 1 -r
  echo    # (optional) move to a new line
  if [[ $REPLY =~ ^[Yy]$ ]] ; then
    echo ". Enabling Redis at boot"
    systemctl enable $REDIS || exit 15
    
    echo ". Enabling SMA-X at boot"
    systemctl enable smax-scripts || exit 16
  fi  
fi


echo "Done!"
