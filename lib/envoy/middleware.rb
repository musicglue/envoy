module Envoy
  module Middleware
    extend ActiveSupport::Concern

    def initialize app, worker
      @app = app
      @worker = worker
    end

    def options
      @worker.class.middleware_options[self.class.options_key_name]
    end

    module ClassMethods
      def options_key name
        @middleware_options_key = name
      end

      def options_key_name
        @middleware_options_key || to_s.underscore
      end
    end
  end
end
