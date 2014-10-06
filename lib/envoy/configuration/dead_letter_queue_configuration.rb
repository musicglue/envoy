module Envoy
  class Configuration
    class DeadLetterQueueConfiguration
      include Validatable

      def initialize(name)
        @name = name
        @delay_seconds = 0
        @message_concurrency = 10
        @message_heartbeat_interval = 5
        @message_retention_period = 1_209_600
        @visibility_timeout = 30
        @worker = 'Envoy::DeadLetterWorker'
        @subscriptions = DeadLetterQueueSubscriptionConfiguration.new @name
      end

      attr_accessor :delay_seconds,
                    :message_concurrency,
                    :message_heartbeat_interval,
                    :message_retention_period,
                    :subscriptions,
                    :visibility_timeout,
                    :worker

      attr_reader :name

      def validate
        unless (0..900).include? delay_seconds
          errors << "#{name}.delay_seconds must be in the range 0..900"
        end

        unless (60..1_209_600).include? message_retention_period
          errors << "#{name}.message_retention_period must be in the range 60..1209600"
        end

        unless (0..43_200).include? visibility_timeout
          errors << "#{name}.visibility_timeout must be in the range 0..43200"
        end

        errors << "#{name}.worker is required" if worker.blank?
      end
    end
  end
end
