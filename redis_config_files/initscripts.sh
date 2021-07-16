#!/bin/bash
#
# Loads the SMA-X scripts into Redis, and stores their hash values under
# 'persistent:scripts'
#
# Author: Attila Kovacs
# Version: 2019 May 19
#
# This script, along with the SMA-X lua scripts, should be stored under
# /usr/share/smax on the Redis server machine, along with the
# 'smax-scripts.service' file, which should be sym-linked to
# /lib/systemd/system so that the scripts are automatically re-loaded upon
# Redis restarts.

LUA="./lua"

load_script() {
  NAME=$1
  SCRIPT=`cat $LUA/$NAME.lua`
  SHA1=`redis-cli script load "$SCRIPT"`
  redis-cli hset scripts $NAME $SHA1
  redis-cli hset persistent:scripts $NAME $SHA1
}

load_script HGetWithMeta
load_script HSetWithMeta
load_script HMGetWithMeta
load_script HMSetWithMeta
load_script GetStruct
load_script HSet

exit 0
