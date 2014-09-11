module Envoy
  class Broker
    include Celluloid
    include Envoy::Logging

    def dispatcher
      @dispatcher ||= Celluloid::Actor[:dispatcher_pool]
    end

    attr_writer :dispatcher

    def mappings
      return @mappings if @mappings
      self.mappings = Envoy.config.mappings
      @mappings
    end

    def mappings= hash
      @mappings = Map.new(hash).to_h
    end

    def process_message(message, queue)
      queue_mappings = mappings[queue.queue_name]
      workflow_class = queue_mappings[message.type] || queue_mappings[:'*']
      workflow_class = workflow_class.constantize if workflow_class.is_a? String

      log_data = message.log_data.merge(component: 'broker', at: 'process_message', queue: queue.queue_name)

      if workflow_class
        debug log_data.merge(worker: workflow_class.name)
        dispatcher.async.process(workflow_class, message)
      else
        debug log_data.merge(worker: nil)
        message.unprocessable
      end
    rescue => e
      error log_data, e
    end
  end
end
