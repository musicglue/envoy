module Envoy
  class SupervisionGroup
    def initialize pool_size, fetcher_config
      @pool_size = pool_size
      @fetcher_config = fetcher_config

      @group = Celluloid::SupervisionGroup.new
      @group.pool Envoy::Broker, as: :broker_pool, size: pool_size
      @group.pool Envoy::Dispatcher, as: :dispatcher_pool, size: pool_size
    end

    def add_custom_actors actors
      actors.each do |actor|
        @group.supervise(actor).async.run
      end
    end

    def add_queue queue
      @group.supervise(
        Envoy::Fetcher,
        @fetcher_config.concurrent_messages_limit,
        Celluloid::Actor[:broker_pool],
        queue).async.run
    end

    def stop
      @group.actors.each do |actor|
        actor.stop if actor.respond_to? :stop
      end
    end
  end
end
