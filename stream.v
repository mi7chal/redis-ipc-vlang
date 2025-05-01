module redisipc

import xiusin.vredis { Pool }
import time
import json

pub struct StreamId {
pub:
	time u64
	seq u64
};

pub fn (id StreamId) str() string {
	return '${id.time}-${id.seq}'
}

pub fn (id StreamId) initialised() bool {
	return id.time != 0 && id.seq != 0
}

pub fn StreamId.from_str(id string) !StreamId {
	parts := id.split('-')

	if parts.len != 2 {
		return error("Invalid stream ID format: ${id}. ID should be in format '<millisecondsTime>-<sequenceNumber>'")
	}

	return StreamId { parts[0].u64(), parts[1].u64() }
}

pub const content_field = 'content';

/// Stream message wrapper object (dto)
pub struct StreamMessage[T] {
pub:
	/// Message id
	id StreamId
	/// Custom message content
	content T
}

pub fn StreamMessage.from_str[T](msg_id string, msg_content string) !StreamMessage[T] {
	id := StreamId.from_str(msg_id)!
	content := json.decode(T, msg_content)!
	return StreamMessage[T]{
		id: id
		content: content
	}
}


/// Structured projected in order to read messages from stream synchronously one by one.
/// Messages are cached, connection is not blocked unless `b_next()` is called.
pub struct ReadStream[T] {
pub:
	name    string
	timeout time.Duration
mut:
	pool    Pool
	last_id StreamId
}

pub fn ReadStream.new[T](pool Pool, name string, optional_timeout ?time.Duration) ReadStream[T] {
	last_id := StreamId {0, 0}

	timeout := optional_timeout or { 0 }

	return ReadStream[T]{
		pool:    pool
		name:    name
		timeout: timeout
		last_id: last_id
	}
}

pub fn (mut rs ReadStream[T]) len() !int {
	mut conn := rs.pool.get()!
	defer {
		conn.release()
	}

	return conn.xlen(rs.name)!
}

pub fn (mut rs ReadStream[T]) last() !StreamMessage[T] {
	mut conn := rs.pool.get()!
	defer {
		conn.release()
	}

	res := conn.send('XREVRANGE', rs.name, '+', '-', 'COUNT', 1)!

	if res.strings().len == 1 && res.strings()[0] == '' {
		return error("No message available.")
	}

	if res.strings().len < 3 {
		return error("Invalid response : ${res.strings()}")
	}

	return StreamMessage.from_str[T](res.strings()[0], res.strings()[2])!
}

pub fn (mut rs ReadStream[T]) b_next() !StreamMessage[T] {
	mut conn := rs.pool.get()!
	defer {
		conn.release()
	}

	id := if rs.last_id.initialised()  { rs.last_id.str() } else { '$' }

	res := conn.send('XREAD', 'COUNT', '1', 'BLOCK', rs.timeout.milliseconds(), 'STREAMS', rs.name, id)!

	if res.bytestr() == '(nil)' {
		return error("Read timeout.")
	}

	if res.strings().len < 4 {
		return error("Invalid response : ${res.strings()}")
	}

	if res.strings()[0] != rs.name {
		return error("Invalid stream name: ${res.strings()[0]}")
	}

	return StreamMessage.from_str[T](res.strings()[1], res.strings()[3])!
}

pub struct WriteStream[T] {
pub:
	name    string
	timeout time.Duration
mut:
	pool    Pool
	max_size usize
}

pub fn WriteStream.new[T](pool Pool, name string, max_size usize) WriteStream[T] {

	return WriteStream[T]{
		pool:    pool
		name:    name
		max_size: max_size
	}
}

pub fn (mut ws WriteStream[T]) publish(message &T) !StreamId {
	msg := json.encode(message)

	mut conn := ws.pool.get()!
	defer {
		conn.release()
	}

	res := conn.send('XADD', ws.name, 'MAXLEN', '~', ws.max_size.str(), '*', content_field, msg)!

	string_id := res.strings()[0] or {
		return error("Failed to retrieve message ID")
	}

	return StreamId.from_str(string_id)!
}

