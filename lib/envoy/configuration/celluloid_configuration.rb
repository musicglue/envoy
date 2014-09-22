module Envoy
  class Configuration
    class CelluloidConfiguration
      include Validatable

      def initialize
        @actors = []
      end

      attr_accessor :actors

      def validate
        if actors.is_a? Array
          unless actors.all? { |actor| actor.is_a?(Class) && actor.ancestors.include?(::Celluloid) }
            errors << 'celluloid.actors may only contain classes that include Celluloid'
          end
        else
          errors << 'celluloid.actors must be an array'
        end
      end
    end
  end
end
