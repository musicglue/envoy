require_relative '../active_record'

module Envoy
  module Middlewares
    class Transactional
      include Middleware
      include Envoy::ActiveRecord

      options_key :transactional

      def call env
        with_transaction(options.except(:on_record_not_unique_failure, :on_serialization_failure)) do
          @app.call env
        end
      rescue ::ActiveRecord::RecordNotUnique
        try_failure_callback :on_record_not_unique_failure
        retry
      rescue ::ActiveRecord::StatementInvalid => error
        if error.message =~ /PG::TRSerializationFailure/
          try_failure_callback :on_serialization_failure
          retry
        end

        raise error
      end

      private

      def try_failure_callback option_name
        return unless callback = options[option_name]
        @worker.send(callback) if @worker.respond_to?(callback)
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
