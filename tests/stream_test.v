module tests

import time
import redis_ipc {WriteStream, ReadStream}
import rand


fn test_write() {
	stream_name := rand.string(10)

	mut stream := build_write_stream[TestMessage](stream_name)!

	msg := build_test_message()

	id := stream.publish(msg)!

	assert id.time > 0, 'Invalid message time'
}

fn test_timeout_empty() {
	stream_name := rand.string(10)

	mut rs := build_read_stream[TestMessage](stream_name, time.second * 1)!

	if msg := rs.b_next() {
		panic("Expected timeout, but got message: ${msg}")
	}
}

fn test_last_empty() {
	stream_name := rand.string(10)

	mut rs := build_read_stream[TestMessage](stream_name, time.second * 1)!

	if msg := rs.last() {
		panic("Expected error, but got: ${msg}")
	}
}

fn test_write_bread() {
	stream_name := rand.string(10)

	mut ws := build_write_stream[TestMessage](stream_name)!
	mut rs := build_read_stream[TestMessage](stream_name, time.second * 10)!

	msg := build_test_message()

	spawn fn [mut ws, msg]() ! {
		time.sleep(time.second * 1)

		ws.publish(msg)!
	}()

	res := rs.b_next()!

	assert res.content == msg, 'Invalid message content'
}

fn test_write_read_last() {
	stream_name := rand.string(10)

	mut ws := build_write_stream[TestMessage](stream_name)!
	mut rs := build_read_stream[TestMessage](stream_name, time.second * 10)!

	msg := build_test_message()

	ws.publish(msg)!

	res := rs.last()!

	assert res.content == msg, 'Invalid message content'
}

fn test_len() {
	stream_name := rand.string(10)

	mut ws := build_write_stream[TestMessage](stream_name)!
	mut rs := build_read_stream[TestMessage](stream_name, time.second * 10)!


	expected_len := 10

	for i in 0 .. expected_len {
		msg := build_test_message()
		ws.publish(msg)!
	}

	len := rs.len()!

	assert len == expected_len, 'Invalid stream length. Expected $expected_len, got ${len}'
}

fn build_write_stream[T](name string) !WriteStream[TestMessage] {
	pool := build_pool()!

	return WriteStream.new[T](pool, name, 1000)
}

fn build_read_stream[T](name string, timeout ?time.Duration) !ReadStream[TestMessage] {
	pool := build_pool()!

	return ReadStream.new[T](pool, name, timeout)
}
