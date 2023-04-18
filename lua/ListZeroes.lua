-- keys:1 (table/meta/struct name)

local result = {}
local k = 1

local list = redis.call('hgetall', KEYS[1])
for i,v in pairs(list) do
  if tonumber(v]) == 0 then
    result[k] = list[i-1]
    k++
  end
end

return result
