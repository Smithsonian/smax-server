local structs = redis.call('keys', KEYS[1] .. '*')
return redis.call('del', unpack(structs))
