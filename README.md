# Redis ipc for Vlang
Simple package which provides a few data structures useful in inter-process or service-to-service communication.
Redis-ipc synchronously implements a few basic data structures using redis accessed by [Vredis](https://github.com/xiusin/vredis).
These structures may be handy and efficient for simple purposes. If you need advanced or sophisticated solution this package
is probably not for you.

This package is made in order to provide ipc which is:
- lightweight
- simple
- efficient

## Introduction
Every data structure is implemented as a wrapper around redis data structure. It uses redis pool to manage connections.
Blocking and non-blocking read operations are available. Structures also contains name, which is used as redis key.
It must be the same for two streams, two queues etc. in order to communicate with each other. It may be treated as an id.

Structures allow to set timeout, which is used in blocking operation. Thread is blocked maximally for this timeout
and when response isn't ready after timout happens, error is returned.

Also, ttl (time to live) is available for the cache.

## Data structures
For now available structures are: task queue, cache and event stream. Each data structure may be used with custom data
type which is passed as a generic argument.

### Task queue
It provides task management based on redis list. Multiple clients may publish and consume tasks, but one task is consumed only by one
client. Please be aware that when task is popped from queue and execution is disrupted the task is lost.

In order to publish tasks use `WriteQueue` and for reading use `ReadQueue`. One queue instance can't consume its own tasks.

### Cache
Cache provides a temporary storage for data. It may be shared between clients, but usage with a single client is also
possible. It provides operations like: saving data, blocking and non-blocking reading. Blocking read blocks thread until element
appears or timeout happens.

### Event stream
It allows for synchronous exchanging events between processes or services. New event can be accessed with a blocking
method and existing ones can be accessed with a non-blocking one.

Blocking read when is used for the first time waits for new stream entries. On later uses it reads first non-read entry if it exist.

Event streaming is based on redis streams, which are used for events caching. Maximum size of stream can be specified.

## Implementations for other languages
For now the twin package is only available only in Rust:
- [RedisIpc Rust](https://crates.io/crates/redis_ipc)

