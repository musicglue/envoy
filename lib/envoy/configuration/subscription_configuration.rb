module Envoy
  class Configuration
    class SubscriptionConfiguration
      def initialize name
        @name = name
        @raw_message_delivery = true
        @mappings = {}
      end

      attr_accessor :raw_message_delivery,
                    :mappings

      def copy_onto subscriptions
        subscriptions.raw_message_delivery = raw_message_delivery
      end

      def add topic, worker
        existing_worker = @mappings[topic]

        if existing_worker
          fail "A worker (#{existing_worker}) is already defined for topic #{topic}."
        end

        @mappings[topic] = worker
      end
    end
  end
end
