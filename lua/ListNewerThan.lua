-- Returns the names of all data that have timestamps more recent than the argument
-- Author: Attila Kovacs
-- Keys: [0]
-- Args: <cutoff-date>
-- Return: a list of pairs of digested keys/values

function lastIndexOf(haystack, fromindex, needle)
    local sub = strsub(haystack, fromindex)
    local i = sub:find(needle)
    if i == nil then 
	return fromindex
    else 
	return lastIndexOf(haystack, i, needle)   
    end
end

local result = {}
local k = 1
local cutoffdate = ARGV[1]

local list = redis.call('hgetall', '<timestamps>')
for i,v in pairs(list) do
  if i%2 == 0 then
    if v > cutoffdate then
      local key = list[i-1]
      local l = lastIndexOf(key, 0, ":")
      local group = strsub(key, 1, l)
      local field = strsub(key, l+2)
      local value = redis.call('hget', group, field)
      result[k] = { key, value }
      k = k+1
    end
  end
end

return result
