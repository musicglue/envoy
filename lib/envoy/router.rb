module Envoy
  class Router
    def initialize config
      @config = config
    end

    def route message
      worker_class = get_worker_class message
      worker_class = worker_class.constantize if worker_class.is_a? String
      worker_class
    end

    private

    def get_worker_class message
      if @config.is_a? Envoy::Configuration::DeadLetterQueueConfiguration
        @config.worker
      else
        @config.subscriptions.mappings[message.type.to_s.underscore]
      end
    end
  end
end
