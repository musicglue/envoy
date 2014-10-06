module Envoy
  class Configuration
    class CallbacksConfiguration
      def initialize
        @invalid_message_dequeued = ->(_, _) {}

        @worker_failed = lambda do |error, worker|
          log_data = {
            component: 'callbacks',
            at: 'worker_failed',
            worker: worker }

          Envoy::Logging.error log_data, error
        end
      end

      attr_accessor :invalid_message_dequeued,
                    :worker_failed
    end
  end
end
