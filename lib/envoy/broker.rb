module Envoy
  class Broker
    include Celluloid
    include Envoy::Logging

    def dispatcher
      @dispatcher ||= Celluloid::Actor[:dispatcher_pool]
    end

    attr_writer :dispatcher

    def process_message(message, queue)
      workflow_class = queue.mappings[message.type.to_s]
      workflow_class = workflow_class.constantize if workflow_class.is_a? String
      log_data = message.log_data.merge(component: 'broker', at: 'process_message', queue: queue.queue_name)

      if workflow_class
        debug log_data.merge(worker: workflow_class.name)
        dispatcher.async.process(workflow_class, message)
      else
        debug log_data.merge(worker: nil)
        message.died
      end
    rescue => e
      error log_data, e
    end
  end
end
