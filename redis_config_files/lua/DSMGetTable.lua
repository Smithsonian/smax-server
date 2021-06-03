-- keys: [0] 
-- arguments: host target key
-- returns name SMA-X table name under which the data can be found

local target = "DSM:"..ARGV[2]
local key = ARGV[3]

-- If the data is stored under the target name, use that
if redis.call('hexists', target, key) then
  return target

local host = "DSM:"..ARGV[1]

-- If the data is stored under the caller's name, use that
if redis.call('hexists', host, key) then
  return  host

-- Otherwise, it may have been a class share from a 3rd host.
-- Use what was last written for that variable.
return redis.call('hget', 'DSM:<last>', key)

