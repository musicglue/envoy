module Envoy
  module Middlewares
    class Timing
      def initialize app, worker
        @app = app
        @worker_class = worker.class
      end

      def call env
        before = Time.now
        @app.call env
        after = Time.now
        duration = (after - before).round 2
        Envoy::Logging.info "component=timing worker=#{@worker_class} duration=#{duration}s"
      end
    end

    module ::Envoy::Worker
      module ClassMethods
        def timing
          middleware << Timing
        end
      end
    end
  end
end
