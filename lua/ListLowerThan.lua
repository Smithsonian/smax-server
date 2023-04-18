-- Returns all fields names that have a numerical value higher then the supplied lower bound
-- Author: Attila Kovacs
-- Keys: [1] table/meta/struct name
-- Arguments: <lower-bound>
-- Return: field names with numerical values higher than the argument
local result = {}
local k = 1
local upperbound = tonumber(ARGV[1])

local list = redis.call('hgetall', KEYS[1])
for i,v in pairs(list) do
  if i%2 == 0 then
    if tonumber(v) < upperbound then
      result[k] = list[i-1]
      k = k+1
    end
  end
end

return result
