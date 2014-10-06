module Envoy
  class Queue
    class Register
      Entry = Struct.new :message, :watchdog

      include Envoy::Logging

      # it's possible that we might end up receiving more messages
      # than there are free slots, so the 'size' of the register
      # is just a soft limit. it will still accept every message.
      def initialize size
        @size = size
        @messages = {}
        @log_data = { component: 'register', size: @size }
      end

      def add message, watchdog
        @messages[message.sqs_id] = Entry.new(message, watchdog)
      end

      def free
        [@size - @messages.keys.count, 0].max
      end

      def remove sqs_id
        @messages.delete sqs_id
      end

      delegate :[], to: :@messages
    end
  end
end
