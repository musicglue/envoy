module Envoy
  module Middlewares
    class Worker
      def initialize app, worker
        @app = app
        @worker = worker
      end

      def call env
        @app.call env
        @worker.process
      end
    end
  end
end
