module Envoy
  module Middlewares
    class ConnectionPool
      include Middleware
      include Envoy::ActiveRecord

      def call env
        with_connection do
          @app.call env
        end
      end
    end

    module ::Envoy::Worker
      module ClassMethods
        def connection_pool
          add_middleware ConnectionPool
        end
      end
    end
  end
end
