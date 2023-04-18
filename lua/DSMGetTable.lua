-- keys: [0] 
-- arguments: host target key
-- returns name SMA-X table name under which the data can be found

local table = "DSM:"..ARGV[2]
local key = ARGV[3]

-- If the data is stored under the target name, use that
if redis.call('hexists', table, key) == 1 then
  return table
end

-- If the data is stored under the caller's name, use that
table = "DSM:"..ARGV[1]
if redis.call('hexists', table, key) == 1 then
  return table
end

-- LUA false maps to Redis nil
return false

