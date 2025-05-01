module tests

import toml
import xiusin.vredis
import rand

fn build_pool() !&vredis.Pool {
	config_file := toml.parse_file("./config.toml")!

	redis_opts := vredis.ConnOpts {
		name: "redis_ipc_tests"
		host: config_file.value("redis.host").default_to("127.0.0.1").string()
		port: config_file.value("redis.port").default_to(6379).int()
		requirepass: config_file.value("redis.password").default_to("").string()
		db: 0
	}

	return vredis.new_pool(vredis.PoolOpt {
		dial: fn [redis_opts] () !&vredis.Redis {
			return vredis.new_client(redis_opts)!
		},
		max_active: 99999
	})
}

struct TestMessage {
pub:
	title string
	random_str string
}

fn build_test_message() TestMessage {
	return TestMessage {
		title: "Hello test!",
		random_str: rand.string(10)
	}
}
