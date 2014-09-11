module Envoy
  class Broker
    class Map
      def initialize hash
        @map = {}

        hash.each do |queue_name, messages|
          queue_name = Envoy::QueueName.new(queue_name).to_s
          queue_map = @map[queue_name] || {}

          messages.each do |message_name, workflow_class|
            queue_map[message_name.to_sym] = workflow_class
          end

          @map[queue_name] = queue_map
        end
      end

      def to_h
        @map
      end
    end
  end
end
