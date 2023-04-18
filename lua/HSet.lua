-- keys: [1] Hash table to add value to
-- arguments: 1:field 2:value
-- returns the result of the HSET call for the {field,value} pair
local table = KEYS[1]
local field = ARGV[1]

local update = false

local prior = redis.call('hget', table, field)
if prior == nil then
  update = true
else
  update = (ARGV[3] ~= prior)
end
  
-- Set the key/value
local result = redis.call('hset', table, field, ARGV[2])

-- Send notification for the table update
if update then
  redis.call('publish', 'smax'..':'..table..':'..field, origin)
end

return result



