module tests

import redisipc {WriteQueue, ReadQueue}
import rand
import time

// test_publish tests if publishing to the `WriteQueue` doesn't produce any errors.
// This test DOES NOT check if the message is actually published.
fn test_publish() {
	queue_name := rand.string(10);

	mut queue := build_write_queue[TestMessage](queue_name)!;

	msg := build_test_message()

	queue.publish(msg)!
}

// test_read_timeout tests if reading from the `ReadQueue` does produce error when queue is empty.
fn test_read_timeout() {
	queue_name := rand.string(12);

	mut queue := build_read_queue[TestMessage](queue_name, time.second)!;

	if res := queue.b_pop() {
		panic("Expected error, but got $res")
	}
}

// test_read_error_on_empty tests if reading from the `ReadQueue` does produce empty result when it should
// (queue is empty).
fn test_read_error_on_empty() {
	queue_name := rand.string(12);

	mut queue := build_read_queue[TestMessage](queue_name, time.second)!

	if res := queue.pop() {
		panic("Expected error, but got $res")
	}
}


// test_write_read_communication tests whether the `WriteQueue` and `ReadQueue` can communicate with each other using
// `publish()` and `b_pop()`.
fn test_write_read_communication() {
	queue_name := rand.string(10);

	mut read_queue := build_read_queue[TestMessage](queue_name, time.second * 10)!
	mut write_queue := build_write_queue[TestMessage](queue_name)!

	msg := build_test_message()

	write_queue.publish(msg)!

	if rcv := read_queue.b_pop() {
		assert rcv.content == msg, "Expected $msg, but got $rcv"
	} else {
		panic("Expected message, but got none")
	}
}

// test_write_read_communication_non_blocking tests if the `WriteQueue` and `ReadQueue` can communicate in a non
// blocking way - tests `publish()` and `next()` methods.
fn test_write_read_communication_non_blocking() {
	queue_name := rand.string(10);

	mut read_queue := build_read_queue[TestMessage](queue_name, time.second * 10)!
	mut write_queue := build_write_queue[TestMessage](queue_name)!

	msg := build_test_message()

	write_queue.publish(msg)!

	// waits to make sure message was published
	time.sleep(time.second * 1)

	if rcv := read_queue.pop() {
		assert rcv.content == msg, "Expected $msg, but got $rcv"
	} else {
		panic("Expected message, but got none")
	}
}

// **Queue test helpers**


fn build_write_queue[T](name string) !WriteQueue[T] {
	pool := build_pool()!

	return WriteQueue.new[T](pool, name)
}

fn build_read_queue[T](name string, timeout ?time.Duration) !ReadQueue[TestMessage] {
	pool := build_pool()!

	return ReadQueue.new[T](pool, name, timeout)
}
