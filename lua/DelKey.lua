-- keys: [1+] SMA-X keywords
-- arguments: (none)
-- returns: (integer) the total number of fields deleted, including in sub-structures, and in parent structures.

local metas = { '<timestamps>', '<types>', '<dims>', '<origins>', '<writes>', '<reads>', '<descriptions>', '<units>', '<coords>' }
local n = 0

local function DelKey (table)
  -- Recursively delete table entries
  for f in redis.call('hkeys', table) do
    DelKey(table..':'..field) 
  end
  
  -- Delete metadata for the table
  for m in metas do
    redis.call("hdel", m, table)
  end
  
  -- Delete the table itself
  if redis.call('del', table) == 1 then
    n = n + 1
  end
end

-- Process each input keyword
for key in KEYS do
  -- Delete the table (if any) recuresively
  DelKey(key)
  
  -- match the substring starting with the last :
  local tail = key:gmatch(':(?:.(?!:))+')

  -- If the keyword can be split...
  if tail ~= nil and tail ~= '' then
    -- Delete reference from parent table
    local parent = table:sub(1, -tail:len())
    local ref = tail:sub(2)
    if redis.call('hdel', parent, ref) == 1 then
      n = n + 1
    end
  end
end

return n
