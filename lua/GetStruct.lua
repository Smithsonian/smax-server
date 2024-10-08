-- keys: [1] Structure name (hash table)
-- arguments: (none)
-- Arrays of:
-- {
--   { struct/substruct names },   -- (Bulk strings) names of structures and nested substructures to follow in order
--   { field names }, { { values}, {types}, {dims}, {timestamps}, {origins}, {serials} },    -- data for first structure name
--  ...                            --  further nested structure data 
-- }

local table = KEYS[1]   -- the name of the hash table

local function HMGetWithMeta (table, fields)
  local values = redis.call('hmget', table, unpack(fields))
  local ids = {}
  for i,field in ipairs(fields) do 
    ids[i] = table..':'..field
  end
  local vtypes = redis.call('hmget', '<types>', unpack(ids))
  local dims = redis.call('hmget', '<dims>', unpack(ids))
  local timestamps = redis.call('hmget', '<timestamps>', unpack(ids))
  local origins = redis.call('hmget', '<origins>', unpack(ids))
  local serials = redis.call('hmget', '<writes>', unpack(ids))
  return { values, vtypes, dims, timestamps, origins, serials }
end

local id = KEYS[1]
local structs = redis.call('keys', id..'*')
local result = {}
result[1] = structs
for i,table in ipairs(structs) do
  local k = 2*i
  local keys = redis.call('hkeys', table);
  result[k] = keys
  result[k+1] = HMGetWithMeta(table, keys)
end
return result
