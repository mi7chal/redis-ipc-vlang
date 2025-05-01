module redis_ipc

import xiusin.vredis {Redis, ConnOpts, new_pool, PoolOpt, Pool}

pub fn connect_default(opts ConnOpts) !&Pool {
	return new_pool(PoolOpt {
		dial: fn [opts] () !&Redis {
			return vredis.new_client(opts)!
		}
	})
}

