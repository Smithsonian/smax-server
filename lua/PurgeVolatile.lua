-- Discards everything other than the 'persistent' branch...
-- Author: Attila Kovacs
local structs = redis.call('keys', '*')
local l = strlen('persistent')
for _,key in ipairs(structs) do
  if strsub(key, 1, l) ~= 'persistent' then
    redis.call('del', key);
  end
end 
