-- Needed for server-side time-stamping.
redis.replicate_commands()

-- keys: [1] Hash table to add values to
-- arguments: 1:origin {2:field1 3:value1 4:type1 5:dim1 } { 6:field2 ... } [T]... 
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
local N = math.floor((#ARGV - leadArgs) / 4)     -- Number of fields

-- A trailing 'T' value may explicitly request to update parent structures also.
local updateParents = false
if #ARGV > leadArgs + 4 * N then
 updateParents = (ARGV[leadArgs + 4 * N + 1] == 'T')
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

local result = redis.call('hset', table, unpack(entries))
redis.call('hset', '<types>', unpack(types))
redis.call('hset', '<dims>', unpack(dims))
redis.call('hset', '<timestamps>', unpack(timestamps))
redis.call('hset', '<origins>', unpack(origins))

-- Bulk update of the serial counters 
local counts = redis.call('hmget', '<writes>', unpack(ids))
for i,ser in pairs(counts) do 
 if ser then
  serials[2*i] = tonumber(ser) + 1 
 else
  serials[2*i] = 1
 end
end 

redis.call('hset', '<writes>', unpack(serials))

local from = origin

if not updateParents then
 -- If this is not a parent structure, tag the message body with '<hmset>'
 from = origin .. ' <hmset>'
end

-- Notify of the table update itself.
redis.call('publish', 'smax:'..table, from)

local notifyLeafs = true

-- <======== BEGIN SMA-specific section ========>
-- Check if updating RM variables...
local isExternalRM = false
if table:sub(1, 3) == 'RM:' then
 -- Check if data is from an rm2smax replicator 
 isExternalRM = (origin:find(':rm2smax') == nil)
end

-- Skip leaf notifications for DSM structures, assuming that DSM structure
-- fields are never 'listened' to individually
notifyLeafs = (table:sub(1, 4) ~= 'DSM:')
-- <========  END SMA-specific section  ========>

if notifyLeafs then
 -- Tag leaf updates with '<hmset>'
 local from = origin .. ' <hmset>'

 -- Send notification of all updated leafs also...
 for i,id in pairs(ids) do
  redis.call('publish', 'smax:'..id, from)
 
  -- <======== BEGIN SMA-specific section ========>
  -- For RM updates not coming from an `rm2smax` replicator, send an
  -- update notification (to an rm2smax replicator)
  if isExternalRM then
   redis.call('publish', table ..':'.. entries[i], entries[i+1])
  end
  -- <========  END SMA-specific section  ========>
 end
end

-- If sending a substructure then we are done...
if not updateParents then
  return result
end

-- Add/uppdate the parent hierachy as needed
local parent = ''
for child in table:gmatch('[^:]+') do
 if parent == '' then
  parent = child
 else
  local id = parent..':'..child
    
  redis.call('hset', parent, child, id)
  redis.call('hset', '<types>', id, 'struct')
  redis.call('hset', '<dims>', id, '1')   
  redis.call('hset', '<timestamps>', id, timestamp)
    
	parent = id
 end
end

return result
