module Envoy
  class Application < Celluloid::SupervisionGroup
    pool Envoy.config.broker,      as: :broker_pool,     size: Envoy.pool_count
    pool Envoy.config.dispatcher,  as: :dispatcher_pool, size: Envoy.pool_count
  end
end
