local result = {}
local k = 1
local cutoffdate = ARGV[1]

local list = redis.call('hgetall', '<timestamps>')
for i,v in pairs(list) do
  if i%2 == 0 then
    if v < cutoffdate then
      result[k] = list[i-1]
      k = k+1
    end
  end
end

return result
