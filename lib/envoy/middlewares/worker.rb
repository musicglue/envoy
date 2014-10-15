module Envoy
  module Middlewares
    class Worker
      include Middleware

      def call env
        @app.call env
        @worker.process
      end
    end
  end
end
