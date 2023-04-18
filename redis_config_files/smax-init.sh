#!/bin/bash
#
# Loads the SMA-X scripts into Redis, and stores their hash values under
# 'scripts'
#
# Author: Attila Kovacs
# Version: 2022 March 1
#
# This script, along with the SMA-X lua scripts, should be stored under
# /usr/share/smax on the Redis server machine, along with the
# 'smax-scripts.service' file, which should be sym-linked to
# /lib/systemd/system so that the scripts are automatically re-loaded upon
# Redis restarts.

LUA="/usr/share/smax/lua"

# Try for up to 5 seconds to get a response from redis...
for i in {1..5}; do
  result=`redis-cli ping`
  if [ "$result" == "PONG" ] ; then
    break
  fi
  if [ $i -eq 5 ]; then
    echo "ERROR! Could not connect to Redis. SMA-X scripts not loaded."
    exit 1
  fi
  sleep 1
done

echo "INFO: Redis is online. Loading SMA-X helper scripts..."

load_script() {
  NAME=$1
  echo -n "> Loading $NAME. New? "
  SCRIPT=`cat $LUA/$NAME.lua`
  SHA1=`redis-cli script load "$SCRIPT"`
  redis-cli hset scripts $NAME $SHA1
}

# Core SMA-X scripts
load_script HSet
load_script HGetWithMeta
load_script HSetWithMeta
load_script HMGetWithMeta
load_script HMSetWithMeta
load_script GetStruct
load_script DSMGetTable

# Utility scripts
load_script ListHigherThan
load_script ListLowerThan
load_script ListNewerThan
load_script ListOlderThan

# Removal and cleanup SMA-X scripts
load_script DelStruct
load_script PurgeVolatile
load_script Purge


exit 0


