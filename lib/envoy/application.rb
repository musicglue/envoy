module Envoy
  class Application < Celluloid::SupervisionGroup
    pool Envoy.config.broker,      as: :broker_pool,     size: (Envoy.config.queues.count + 1)
    pool Envoy.config.dispatcher,  as: :dispatcher_pool, size: (Envoy.config.queues.count + 1)
  end
end
