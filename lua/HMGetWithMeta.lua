-- keys: [1] Hash table to get values from
-- arguments: field1 field2 ...
-- returns an array of arrays { {values}, {types}, {dims}, {timestamps}, {origins}, {serials} }
local table = KEYS[1]
local values = redis.call('hmget', table, unpack(ARGV))

local ids = {}
for i,field in ipairs(ARGV) do 
 ids[i] = table..':'..field
end

local vtypes = redis.call('hmget', '<types>', unpack(ids))
local dims = redis.call('hmget', '<dims>', unpack(ids))
local timestamps = redis.call('hmget', '<timestamps>', unpack(ids))
local origins = redis.call('hmget', '<origins>', unpack(ids))
local serials = redis.call('hmget', '<writes>', unpack(ids))
return { values, vtypes, dims, timestamps, origins, serials }

