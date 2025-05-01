module tests

import rand
import time
import redisipc { Cache }

fn test_random_element_not_exists() {
	name := rand.string(10)
	mut cache := build_cache[TestMessage](name, time.second * 10, time.second * 10)!
	field := rand.string(8)


	exists := cache.exists(field)!

	assert !exists, "Expected cache key $field to not exist, but it does"
}

fn test_element_set_and_get() {
	name := rand.string(10)
	mut cache := build_cache[TestMessage](name, time.second * 10, time.second * 10)!
	field := rand.string(8)
	value := build_test_message()
	cache.set(field, value)!
	field_val := cache.get(field)!

	assert field_val.content == value, "Expected $value, but got ${field_val.content}"
}

fn test_non_existing_get() {
	name := rand.string(10)
	mut cache := build_cache[TestMessage](name, time.second * 10, time.second * 10)!
	field := rand.string(8)

	if res := cache.get(field) {
		panic("Expected error, but got $res")
	}
}

fn test_element_set_exists() {
	name := rand.string(10)
	mut cache := build_cache[TestMessage](name, time.second * 10, time.second * 10)!
	field := rand.string(8)
	value := build_test_message()
	cache.set(field, value)!

	exists := cache.exists(field)!

	assert exists, "Expected cache key $field to exist, but it doesn't"
}

fn test_element_blocking_get() {
	name := rand.string(10)
	mut cache := build_cache[TestMessage](name, time.second * 10, time.second * 10)!
	field := rand.string(8)
	value := build_test_message()
	cache.set(field, value)!

	res := cache.b_get(field, value)!
	assert res.content == value, "Expected $value, but got ${res.content}"
}

fn test_element_blocking_get_timeout() {
	name := rand.string(10)
	mut cache := build_cache[TestMessage](name, time.second * 10, time.second)!
	field := rand.string(8)

	if res := cache.b_get(field, build_test_message()) {
		panic("Expected error, but got $res")
	}
}

fn test_element_deletion() {
	name := rand.string(10)
	mut cache := build_cache[TestMessage](name, none, time.second * 10)!
	field := rand.string(8)
	value := build_test_message()
	cache.set(field, value)!
	time.sleep(time.second)

	exists_before := cache.exists(field)!
	assert exists_before == true, "Expected cache key $field to exist, but it doesn't"

	time.sleep(time.second)

	cache.delete(field)!

	time.sleep(time.second)

	exists_after := cache.exists(field)!
	assert exists_after == false, "Expected cache key $field to not exist, but it does"
}

// ** Cache test helpers **

fn build_cache[T](name string, ttl ?time.Duration, timeout ?time.Duration) !Cache[T] {
	pool := build_pool()!

	return Cache.new[T](pool, name, ttl, timeout)
}
