module Envoy
  module Middlewares
    class Airbrake
      def initialize app, worker
        @app = app
        @headers = @worker.message.headers
      end

      def call env
        @app.call env
      rescue => e
        ::Airbrake.notify_or_ignore e, parameters: { message: @headers }
        raise e
      end
    end
  end
end
