-- keys: none
-- arguments: pattern
-- returns Number of fields purged from database

local n = 0

for i,key in pairs(redis.call('keys', ARGV[1])) do

  -- If key is a hash table the interate through elements to remove associated metadata
  if redis.call('type', key) == 'hash' do
    for j,field in pairs(redis.call('hkeys', key)) do
      local id = key .. ':' .. field
      redis.call('hdel', '<types>', id)
      redis.call('hdel', '<dims>', id)
      redis.call('hdel', '<timestamps>', id)
      redis.call('hdel', '<origins>', id)
      redis.call('hdel', '<writes>', id)
      redis.call('hdel', '<units>', id)
      redis.call('hdel', '<descriptions>', id)
      n = n+1
    end
  end

  -- unlink the key (will be deleted in background)   
  redis.call('unlink', key)
end

-- Delete coordinate system definitions also.
local keys = redis.call('keys', '<coords>:' .. ARGV[1])
for i,key in pairs(keys) do
  redis.call('unlink', key)
end

return n