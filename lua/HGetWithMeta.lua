#!lua flags=no-writes

-- The SMA-X library for Redis
-- Author: Attila Kovacs
-- Version: 11 December 2024
-- 
-- GitHub: Smithsonian/smax-server

-- keys: [1] Hash table to get value from
-- arguments: field
-- returns an array of { value, type, dim, timestamp, origin, serial }
local table = KEYS[1]
local field = ARGV[1]
local value = redis.call('hget', table, field)
local id = table .. ':' .. field
local vtype = redis.call('hget', '<types>', id)
local dim = redis.call('hget', '<dims>', id)
local timestamp = redis.call('hget', '<timestamps>', id)
local origin = redis.call('hget', '<origins>', id)
local serial = redis.call('hget', '<writes>', id)
return { value, vtype, dim, timestamp, origin, serial }

