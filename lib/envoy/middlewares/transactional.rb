module Envoy
  module Middlewares
    class Transactional
      include Middleware
      include Envoy::ActiveRecord

      options_key :transactional

      def call env
        with_transaction(options) do
          @app.call env
        end
      rescue ActiveRecord::StatementInvalid => error
        if error.message =~ /PG::TRSerializationFailure/
          callback = options[:on_serialization_failure]
          @worker.send callback if callback && @worker.respond_to? callback

          retry
        end

        raise error
      end
    end

    module ::Envoy::Worker
      module ClassMethods
        def transactional opts = {}
          add_middleware Transactional, opts
        end
      end
    end
  end
end
