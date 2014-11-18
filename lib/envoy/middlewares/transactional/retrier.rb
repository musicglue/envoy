module Envoy
  module Middlewares
    class Transactional
      class Retrier
        def initialize options = {}
          @options = options.reverse_merge(tries: 10, sleep: 0)
        end

        def call &block
          retryable(@options.merge(on: [::ActiveRecord::RecordNotUnique])) do
            retryable(@options.merge(matching: /TRDeadlockDetected|TRSerializationFailure/)) do
              yield block
            end
          end
        end
      end
    end
  end
end
