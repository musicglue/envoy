module Envoy
  class Configuration
    class QueueConfiguration
      include Validatable

      HEARTBEAT_INTERVAL_EXTENSION = 5

      def initialize name
        @name = name
        @delay_seconds = 0
        @message_concurrency = 10
        @message_heartbeat_interval = 25
        @message_retention_period = 1_209_600
        @visibility_timeout = 30
        @subscriptions = SubscriptionConfiguration.new @name
      end

      attr_accessor :delay_seconds,
                    :message_concurrency,
                    :message_heartbeat_interval,
                    :message_retention_period,
                    :visibility_timeout,
                    :subscriptions

      attr_reader :name

      def redrive_policy
        @redrive_policy ||= RedrivePolicyConfiguration.new self
      end

      def subscribed_topics
        subscriptions.mappings.keys.map do |topic|
          EnvironmentalName.new(topic).to_s
        end
      end

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

        unless message_heartbeat_interval > 5
          errors << "#{name}.message_heartbeat_interval must be greater than 5 seconds"
        end

        unless message_heartbeat_interval <= (visibility_timeout - 5)
          errors << "#{name}.message_heartbeat_interval must be at least 5 seconds less than it's visibility_timeout"
        end

        redrive_policy.valid?
        errors.push *(redrive_policy.errors)
      end

      def copy_onto queue
        queue.delay_seconds = delay_seconds
        queue.message_retention_period = message_retention_period
        queue.visibility_timeout = visibility_timeout

        redrive_policy.copy_onto queue.redrive_policy if queue.respond_to? :redrive_policy
      end
    end
  end
end
