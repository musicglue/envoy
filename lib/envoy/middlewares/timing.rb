module Envoy
  module Middlewares
    class Timing
      include Middleware

      def initialize app, worker
        super
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
          add_middleware Timing
        end
      end
    end
  end
end
