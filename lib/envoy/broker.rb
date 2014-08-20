module Envoy
  class Broker
    include Celluloid
    include Celluloid::Logger

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
      workflow_class = queue_mappings[message.type] || queue_mappings['*']
      workflow_class = workflow_class.constantize if workflow_class.is_a? String

      description = "#{message.type} message was received from #{queue.queue_name} queue"

      if workflow_class
        debug "#{description} and was routed to #{workflow_class}"
        dispatcher.async.process(workflow_class, message)
      else
        debug "#{description} and was unrouteable"
        message.unprocessable
      end
    rescue => e
      error e.inspect
    end
  end

  class Map
    def initialize hash
      @map = {}

      hash.each do |queue_name, messages|
        queue_name = Envoy::QueueName.new(queue_name).to_s
        queue_map = @map[queue_name] || {}

        messages.each do |message_name, workflow_class|
          queue_map[message_name.to_s] = workflow_class
        end

        @map[queue_name] = queue_map
      end
    end

    def to_h
      @map
    end
  end
end
