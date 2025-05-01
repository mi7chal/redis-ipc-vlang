module redis_ipc

import json
import xiusin.vredis { Pool }
import rand
import time

@[noinit]
pub struct QueueMessage[T] {
pub:
	uuid    string
	content T
}

pub fn QueueMessage.new[T](content &T) QueueMessage[T] {
	return QueueMessage[T]{
		uuid:    rand.uuid_v4()
		content: content
	}
}

pub fn QueueMessage.from_str[T](message string) !QueueMessage[T] {
	return json.decode(QueueMessage[T], message)!
}

pub struct WriteQueue[T] {
pub:
	name string
mut:
	pool Pool
}

pub fn WriteQueue.new[T](pool &Pool, name string) WriteQueue[T] {
	return WriteQueue[T]{
		pool: pool
		name: name
	}
}

pub fn (mut wq WriteQueue[T]) publish(mc &T) ! {
	message := QueueMessage.new(mc)
	message_encoded := json.encode(message)
	mut conn := wq.pool.get()!
	defer {
		conn.release()
	}

	conn.lpush(wq.name, message_encoded)!
}

pub struct ReadQueue[T] {
pub:
	name    string
	timeout time.Duration
mut:
	pool Pool
}

pub fn ReadQueue.new[T](pool Pool, name string, optional_timeout ?time.Duration) ReadQueue[T] {
	timeout := optional_timeout or { 0 }

	return ReadQueue[T]{
		name:    name
		timeout: timeout
		pool:    pool
	}
}

pub fn (mut rq ReadQueue[T]) pop() !QueueMessage[T] {
	mut conn := rq.pool.get()!
	defer {
		conn.release()
	}

	res := conn.rpop(rq.name)!

	return QueueMessage.from_str[T](res)!
}

pub fn (mut rq ReadQueue[T]) b_pop() !QueueMessage[T] {
	mut conn := rq.pool.get()!
	defer {
		conn.release()
	}

	res := conn.brpop(rq.name, int(rq.timeout.seconds()))!

	return QueueMessage.from_str[T](res.value.str())!
}

fn (mut rq ReadQueue[T]) next() ?QueueMessage[T] {
	mut conn := rq.pool.get() or { return none }
	defer {
		conn.release()
	}

	res := conn.rpop(rq.name) or { return none }

	return QueueMessage.from_str[T](res) or { return none }
}
