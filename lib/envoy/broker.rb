module Envoy
  class Broker
    include Celluloid
    include Envoy::Logging

    def dispatcher
      @dispatcher ||= Celluloid::Actor[:dispatcher_pool]
    end

    attr_writer :dispatcher

    def process_message(message, queue)
      worker_class = if queue.config.is_a? Envoy::Configuration::DeadLetterQueueConfiguration
                       queue.config.worker
                     else
                       queue.config.subscriptions.mappings[message.type.to_s]
                     end

      worker_class = worker_class.constantize if worker_class.is_a? String

      log_data = message.log_data.merge(component: 'broker', at: 'process_message', queue: queue.queue_name)

      if worker_class
        debug log_data.merge(worker: worker_class.name)
        dispatcher.async.process(worker_class, message)
      else
        debug log_data.merge(worker: nil)
        message.died
      end
    rescue => e
      error log_data, e
    end
  end
end
