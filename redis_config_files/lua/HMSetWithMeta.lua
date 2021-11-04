-- Needed for server-side time-stamping.
redis.replicate_commands()

-- keys: [1] Hash table to add values to
-- arguments: 1:origin {2:field1 3:value1 4:type1 5:dim1 } { 6:field2 ... } ... 
-- returns the result of the HMSET call for the {field,value} pairs
local table = KEYS[1]   -- the name of the hash table
local origin = ARGV[1]

-- Timestamp
local time = redis.call('time')
local timestamp = time[1].."."..string.format("%06d", time[2])

-- arrays / tables we'll need
local ids = {}          -- composited meta IDs for all fields to be set

-- Pairs to pass to HMSET
local entries = {}      -- {field,value} pairs
local types = {}        -- {field,vartype} pairs
local dims = {}         -- {field,vardim} pairs
local timestamps = {}   -- {field,timestamp} pairs
local origins = {}      -- {field,origin} pairs
local serials = {}      -- {field,serial} pairs

local leadArgs = 1
local N = (#ARGV - leadArgs) / 4     -- Number of fields

-- A trailing 0 or non-zero value may explicitly select 
-- whether or not we want to notify parent structures
local notifyParents = 'T'
if #ARGV > leadArgs + 4 * N then
  notifyParents = ARGV[leadArgs + 4 * N + 1];
end

for k=1,N do 
 local i = leadArgs + 4*k-3     -- i is the original ARGV index
 local j = 2 * k - 1            -- j is the {key,value} pairs list index
 
 local field = ARGV[i]          -- field name
 local id = table..':'..field   -- the composited meta id

 ids[k] = id

 entries[j] = field             -- set the pair names...
 types[j] = id
 dims[j] = id
 timestamps[j] = id
 origins[j] = id
 serials[j] = id

 j = j+1                    -- set the pair values...
 entries[j] = ARGV[i+1]     -- value
 types[j] = ARGV[i+2]       -- type
 dims[j] = ARGV[i+3]        -- dim
 timestamps[j] = timestamp
 origins[j] = origin 
end

local result = redis.call('hmset', table, unpack(entries))
redis.call('hmset', '<types>', unpack(types))
redis.call('hmset', '<dims>', unpack(dims))
redis.call('hmset', '<timestamps>', unpack(timestamps))
redis.call('hmset', '<origins>', unpack(origins))

-- Bulk update of the serial counters 
local counts = redis.call('hmget', '<writes>', unpack(ids))
for i,ser in pairs(counts) do 
 if ser then
  serials[2*i] = tonumber(ser) + 1 
 else
  serials[2*i] = 1
 end
end 
redis.call('hmset', '<writes>', unpack(serials))

local isExternalRMUpdate = false
 local target = table:sub(4)
 if origin:sub(1, target:len()) ~= target then
   isExternalRMUpdate = true
 end
end

-- Send notification of this update
for i,id in pairs(ids) do
 redis.call('publish', 'smax:'..id, origin)
 
 -- For RM updates coming from outside the targeted antenna send a notification
 -- to the antenna's RM connector, including the data
 if isExternalRMUpdate then
  redis.call('publish', table, field .. "=" .. value)
 end
end
end


-- Add/uppdate the parent hierachy as needed
local parent = ''
local newparent = 1
for child in table:gmatch('[^:]+') do
 if parent == '' then
  parent = child
 else
  local id = parent..':'..child
    
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

