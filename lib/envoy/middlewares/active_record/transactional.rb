module Envoy
  module Middlewares
    class ActiveRecord
      class Transactional
        def initialize app, worker
          @app = app
          @worker = worker
        end

        def call env
          ::ActiveRecord::Base.connection_pool.with_connection do
            ::ActiveRecord::Base.transaction do
              @app.call env
            end
          end
        end
      end

      module ::Envoy::Worker
        module ClassMethods
          def transactional_active_record
            middleware << Transactional
          end
        end
      end
    end
  end
end
