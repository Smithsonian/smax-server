#!lua flags=no-writes

-- The SMA-X library for Redis
-- Author: Attila Kovacs
-- Version: 21 December 2024
-- 
-- GitHub: Smithsonian/smax-server

-- keys: none
-- arguments: id

-- returns an array of { type, dim, timestamp, origin, serial }
local id = ARGV[1]

local vtype = redis.call('hget', '<types>', id)
local dim = redis.call('hget', '<dims>', id)
local timestamp = redis.call('hget', '<timestamps>', id)
local origin = redis.call('hget', '<origins>', id)
local serial = redis.call('hget', '<writes>', id)

return { vtype, dim, timestamp, origin, serial }
