#!/bin/bash
#
# Loads the SMA-X function into Redis.
#
# Author: Attila Kovacs
# Version: 2024 December 11

LUA="/usr/share/smax/lua"

if [ "$1" != "" ] ; then 
  LUA="$1"
fi

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

echo "INFO: Redis is online. Loading SMA-X functions..."

load_function() {
  NAME=$1
  echo -n "> Loading $NAME. New? "
  `cat $LUA/$NAME | redis-cli function load replace`
}

load_function smax.lib

exit 0


