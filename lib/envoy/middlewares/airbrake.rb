module Envoy
  module Middlewares
    class Airbrake
      include Middleware

      def initialize app, worker
        super
        @headers = worker.message.headers
      end

      def call env
        @app.call env
      rescue => e
        ::Airbrake.notify_or_ignore e, parameters: { message: @headers }
        raise e
      end
    end

    module ::Envoy::Worker
      module ClassMethods
        def airbrake
          add_middleware Airbrake
        end
      end
    end
  end
end
