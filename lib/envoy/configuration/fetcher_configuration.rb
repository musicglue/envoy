module Envoy
  class Configuration
    class FetcherConfiguration
      include Validatable

      def initialize
        @concurrent_messages_limit = 10
      end

      attr_accessor :concurrent_messages_limit

      def validate
        return unless concurrent_messages_limit.to_i < 1

        errors << 'fetcher.concurrent_messages_limit must be an integer >= 1'
      end
    end
  end
end
