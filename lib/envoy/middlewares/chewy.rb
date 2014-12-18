module Envoy
  module Middlewares
    class Chewy
      include Middleware

      def call env
        ::Chewy.strategy(:atomic) do
          @app.call env
        end
      end
    end

    module ::Envoy::Worker
      module ClassMethods
        def chewy
          add_middleware Chewy
        end
      end
    end
  end
end
