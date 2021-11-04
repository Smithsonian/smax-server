-- Needed for server-side timestamping...
redis.replicate_commands()

-- keys: [1] Hash table to add value to
-- arguments: 1:origin 2:field 3:value 4:type 5:dim
-- returns the result of the HSET call for the {field,value} pair
local table = KEYS[1]
local origin = ARGV[1]
local field = ARGV[2]
local value = ARGV[3]

-- Timestamp
local time = redis.call('time')
local timestamp = time[1].."."..string.format("%06d", time[2])
  
-- Set the key/value
local result = redis.call('hset', table, field, value)

-- Set the corresponding metadata
local id = table .. ':' .. field
redis.call('hset', '<types>', id, ARGV[4])
redis.call('hset', '<dims>', id, ARGV[5])
redis.call('hset', '<timestamps>', id, timestamp)
redis.call('hset', '<origins>', id, origin)
redis.call('hincrby', '<writes>', id, '1')

-- Send notification for the table update
redis.call('publish', 'smax:'..id, origin)
 
-- For RM updates coming from outside the targeted antenna send a notification
-- to the antenna's RM connector, including the data
if table:sub(1, 3) == "RM:" then
 local target = table:sub(4)
 if origin:sub(1, target:len()) ~= target then
  redis.call('publish', table, field .. "=" .. value)
 end
end
 
-- Add/update the parent hierachy as needed
local parent = ''
local newparent = 1
for child in table:gmatch('[^:]+') do
 if parent == '' then
  parent = child
 else
  id = parent..':'..child
  if newparent == 1 then
   newparent = redis.call('hset', parent, child, id)
   if newparent == 1 then 
    redis.call('hset', '<types>', id, 'struct')
    redis.call('hset', '<dims>', id, '1')
   end
  end
    
  redis.call('hset', '<timestamps>', id, timestamp)

  parent = id
 end
end

return result
