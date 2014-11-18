require_relative '../active_record'
require_relative 'transactional/retrier'

module Envoy
  module Middlewares
    class Transactional
      include Middleware
      include Envoy::ActiveRecord

      options_key :transactional

      def call env
        Retrier.new(retrier_options).call do
          with_transaction(transaction_options) do
            @app.call env
          end
        end
      end

      private

      def retrier_options
        retrier_options = options.slice :tries, :sleep, :on_retriable_error
        on_error = retrier_options.delete :on_retriable_error
        retrier_options[:exception_cb] = @worker.method(on_error) unless on_error.blank?
        retrier_options
      end

      def transaction_options
        options.slice :requires_new, :joinable, :isolation
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
