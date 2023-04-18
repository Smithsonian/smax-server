-- keys: [1] Structure name (hash table)
-- arguments: (none)
-- returns: (integer) the number of keys deleted, including sub-structures.

local structs = redis.call('keys', KEYS[1] .. '*')
return redis.call('del', unpack(structs))
