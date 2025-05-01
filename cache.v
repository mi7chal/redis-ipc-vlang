module redisipc

import time
import xiusin.vredis { Pool }
import json

// CacheElement is a wrapper for elements in cache.
@[noinit]
pub struct CacheElement[T] {
pub:
	timestamp i64 // should be changed to u128 in the future
	content T
}

// CacheElement.new creates a new CacheElement with the current timestamp and the provided content.
pub fn CacheElement.new[T](content T) CacheElement[T] {
	return CacheElement[T]{
		timestamp: time.now().unix()
		content: content
	}
}

// CacheElement.from_str decodes a JSON string into a CacheElement.
pub fn CacheElement.from_str[T](message string) !CacheElement[T] {
	return json.decode(CacheElement[T], message)!
}

// Cache is a shared caching struct based on a Redis hash that stores elements with a TTL.
// See also https://redis.io/docs/latest/develop/data-types/hashes/
pub struct Cache[T] {
pub:
	name string
	ttl ?time.Duration
	read_timeout time.Duration
mut:
	pool &Pool
}

// new creates a new Cache instance with the provided Redis pool, name, optional TTL, and read timeout.
pub fn Cache.new[T](pool &vredis.Pool, name string, optional_ttl ?time.Duration, optional_read_timeout time.Duration) Cache[T] {
	ttl := optional_ttl or { 0 }

	return Cache[T]{
		pool: pool
		name: name
		ttl: ttl
		read_timeout: optional_read_timeout
	}
}

// get retrieves an element from the cache by its key. If the key does not exist, it returns an error.
pub fn (mut cache Cache[T]) get(key string) !CacheElement[T] {
	mut conn := cache.pool.get()!
	defer {
		conn.release()
	}

	res := conn.hget(cache.name, key)!

	return CacheElement.from_str[T](res)!
}

// b_get retrieves an element from the cache by its key, blocking until the key is available or a timeout occurs.
pub fn (mut cache Cache[T]) b_get(key string, value T) !CacheElement[T] {
	sw := time.new_stopwatch()
	sleep_duration := time.millisecond * 50

	for {
		if elem := cache.get(key) {
			return elem
		}

		if sw.elapsed() > cache.read_timeout {
			return error("Timeout while waiting for cache key: $key")
		}

		time.sleep(sleep_duration)
	}

	return error("Timeout while waiting for cache key: $key")
}

// set stores an element in the cache with the provided key and value. If a TTL is set, it will be applied.
pub fn (mut cache Cache[T]) set(key string, value T) ! {
	mut conn := cache.pool.get()!
	defer {
		conn.release()
	}

	element_encoded := json.encode(CacheElement.new(value))

	conn.hset(cache.name, key, element_encoded)!

	if ttl := cache.ttl {
		conn.send('HEXPIRE', key, int(ttl.seconds()), 'FIELDS', 1, key)!
	}
}

// exists checks if a field exists in the cache.
pub fn (mut cache Cache[T]) exists(field string) !bool {
	mut conn := cache.pool.get()!

	defer {
		conn.release()
	}

	return conn.hexists(cache.name, field)!
}

// delete removes an element from the cache by its key
pub fn(mut cache Cache[T]) delete(key string) ! {
	mut conn := cache.pool.get()!
	defer {
		conn.release()
	}

	conn.hdel(cache.name, key)!
}



