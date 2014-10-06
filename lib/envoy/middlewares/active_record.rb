module Envoy
  module Middlewares
    class ActiveRecord
      def initialize app, worker
        @app = app
        @worker = worker
      end

      def call env
        ::ActiveRecord::Base.connection_pool.with_connection do
          @app.call env
        end
      end
    end

    module ::Envoy::Worker
      module ClassMethods
        def active_record
          middleware << ActiveRecord
        end
      end
    end
  end
end
