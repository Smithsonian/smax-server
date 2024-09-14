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

if [ $EUID -ne 0 ]
  then echo "Please run as root"
  exit 1
fi

# You can configure DESTDIR before calling this script to install to a location other
# than /usr (e.g. /usr/local or /opt).
if [ "$DESTDIR" == "" ] ; then
  DESTDIR="/usr"
fi

# Create /usr/share/smax and its lua/ sub-directory
SMAX="$(DESTDIR)/share/smax"

# Copy LUA script over to /usr/share/smax
mkdir -p $SMAX/lua || exit 1
cp -a lua $SMAX || exit 2

# install script loader and systemd unit file
install -m 755 smax-init.sh /usr/bin/ || ( exho  exit 3
install -m 644 smax-scripts.service /etc/systemd/system/ || exit 4

# Register smax-scripts with systemd
systemctl daemon-reload || exit 5

# if you call the script with a single argument 'auto', then it will install 
# a default without asking any questions. (Without the option, the installer
# will ask you to make some choices.)
if [ "$1" == "auto" ] ; then
  # automatic installation 

  sed -i '/^.*BEGIN SMA.*/,/^.*END SMA.*$/d' *.lua || exit 6
  systemctl restart smax-scripts || exit 7
  systemctl enable redis || exit 8
  systemctl enable smax-scripts || exit 9
else
  # prompt for choices

  read -p "Are you going to use SMA-X at the SMA? " -n 1 -r
  echo    # (optional) move to a new line
  if [[ $REPLY =~ ^[Yy]$ ]] ; then 
    sed -i '/^.*BEGIN SMA.*/,/^.*END SMA.*$/d' *.lua || exit 10
  fi

  read -p "start redis with SMA-X scripts at this time? " -n 1 -r
  echo    # (optional) move to a new line
  if [[ $REPLY =~ ^[Yy]$ ]] ; then
    systemctl restart smax-scripts || exit 11
  fi
  
  read -p "Enable and start SMA-X at boot time? " -n 1 -r
  echo    # (optional) move to a new line
  if [[ $REPLY =~ ^[Yy]$ ]] ; then
    systemctl enable redis || exit 12
    systemctl enable smax-scripts || exit 13
  fi  
fi

