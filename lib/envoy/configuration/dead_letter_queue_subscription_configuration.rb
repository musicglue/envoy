module Envoy
  class Configuration
    class DeadLetterQueueSubscriptionConfiguration
      def initialize name
        @name = name
        @raw_message_delivery = true
      end

      attr_accessor :raw_message_delivery
    end
  end
end
