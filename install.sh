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
# 09/26/2024
#

set -e


if [[ $1 =~ ^(help|--help|-h|-\?)$ ]] ; then
  echo 
  echo " Syntax: sudo ./install.sh [mode]"
  echo
  echo " Option [mode]:"
  echo
  echo "    auto        Automatic installation, and start-up"
  echo "    sma         Automatic installation for use at the SMA"
  echo "    help        this help screen"
  echo
  echo " Environment:"
  echo
  echo "    DESTDIR     Deployment root (default: '/usr')"
  echo "    PREFIX      Staging prefix (no start-up if not empty)"
  echo
  exit 0
fi

if [ $EUID -ne 0 ] ; then 
  echo "Please run as root" 
  exit 1
fi

# Deployment root
if [ "$DESTDIR" == "" ] ; then
  DESTDIR="/usr"
fi

# Staging root
if [ "$PREFIX" == "" ] ; then
  STAGE=$DESTDIR
else
  STAGE=$PREFIX/$DESTDIR
fi

# Create /usr/share/smax and its lua/ sub-directory
SMAX="$STAGE/share/smax"
SYSTEMD="$PREFIX/etc/systemd/system"

# ============================================================================
# Part 1: copying things in place

# Copy LUA script over to /usr/share/smax
echo ". Creating $SMAX/lua directory"
mkdir -p $SMAX/lua

echo ". Copying LUA scripts to $SMAX/lua"
install -m 644 -D lua/* $SMAX/lua/

# install script loader and systemd unit file
echo ". Copying script loader to $STAGE/bin"
install -m 755 smax-init.sh $STAGE/bin/

echo ". Setting DESTDIR in script loader"
sed -i "s:/usr:$DESTDIR:g" $STAGE/bin/smax-init.sh

echo ". Copying systemd sevice unit to $SYSTEMD"
install -m 644 smax-scripts.service $SYSTEMD/

echo ". Setting DESTDIR in systemd service unit"
sed -i "s:/usr:$DESTDIR:g" $SYSTEMD/smax-scripts.service

if [[ ! $1 =~ ^(sma|SMA)$ ]] ; then
  echo ". Removing SMA-specific sections from scripts"
  sed -i '/^.*BEGIN SMA.*/,/^.*END SMA.*/d' $SMAX/lua/*.lua
fi

# Register smax-scripts with systemd
echo ". Reloading systemd daemon"
systemctl daemon-reload

if [ "$PREFIX" != "" ] ; then
  echo "PREFIX is set, staging only."
  echo "Done."
  exit 0
fi 

# ============================================================================
# Part 2: starting things up


# Checking for systemd...
echo "Checking for systemctl..."
which systemctl >> /dev/null 2>&1

# Don't exit on error return while we check variants
set +e

# On some distros the service is redis, on others is redis-server...
for name in 'redis-server' 'redis' 'valkey-server' 'valkey' ; do
  systemctl status $name > /dev/null 2>&1;
  if [ $? -eq 0 ] ; then
    REDIS=$name; 
    break
  fi
done

# Back to exit on error...
set -e

if [ "$REDIS" == "" ] ; then
  echo "ERROR! You must install redis or valkey or equivalent..."
  exit 2
fi

if [ "$REDIS" != "redis" ] ; then
  echo "Updating systemd service name to $REDIS.service" 
  sed -i "s:redis.service:$REDIS.service:g" $SYSTEMD/smax-scripts.service
fi

START_SMAX=1
ENABLE_SMAX=1

# if you call the script with a single argument 'auto', then it will install 
# a default without asking any questions. (Without the option, the installer
# will ask you to make some choices.)
if [[ $1 =~ ^(auto|sma|SMA)$ ]] ; then
  # automatic installation
  echo "Automatic installation..." 
  
else
  # prompt for choices
  echo "Manual installation..." 

  read -p "Are you going to use SMA-X at the SMA? " -n 1 -r
  echo    # (optional) move to a new line
  if [[ $REPLY =~ ^[Yy]$ ]] ; then 
    echo ". Removing SMA-specific sections from scripts"
    sed -i '/^.*BEGIN SMA.*/,/^.*END SMA.*$/d' *.lua
  fi

  read -p "start redis with SMA-X scripts at this time? " -n 1 -r
  echo    # (optional) move to a new line
  if [[ ! $REPLY =~ ^[Yy]$ ]] ; then 
    START_SMAX=0
  fi
  
  read -p "Enable and start SMA-X at boot time? " -n 1 -r
  echo    # (optional) move to a new line
  if [[ ! $REPLY =~ ^[Yy]$ ]] ; then
    ENABLE_SMAX=0
  fi  
fi

if [ $START_SMAX -ne 0 ] ; then
  echo ". Starting smax-scripts service"
  systemctl restart smax-scripts
fi 
 
if [ $ENABLE_SMAX -ne 0 ] ; then
  echo ". Enabling Redis at boot"
  systemctl enable $REDIS
  
  echo ". Enabling SMA-X at boot"
  systemctl enable smax-scripts
fi

echo "Done!"
