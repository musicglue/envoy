module Envoy
  module Middlewares
    class Airbrake
      def initialize app, worker
        @app = app
        @worker = worker
      end

      def call env
        @app.call env
      rescue => e
        ::Airbrake.notify_or_ignore e, parameters: { message: @worker.message.headers }
        raise e
      end
    end
  end
end
