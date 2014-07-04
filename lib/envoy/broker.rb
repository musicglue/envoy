module Envoy
  class Broker
    include Celluloid
    include Celluloid::Logger

    def dispatcher
      @dispatcher ||= Celluloid::Actor[:dispatcher_pool]
    end

    attr_writer :dispatcher

    def mappings
      @mappings ||= Envoy.config.mappings
    end

    attr_writer :mappings

    def process_message(message)
      mapping = mappings[message.type]

      if mapping
        dispatcher.async.process(mapping.constantize, message)
      else
        message.unprocessable
      end
    rescue => e
      error e.inspect
    end
  end
end
