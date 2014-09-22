module Envoy
  class Configuration
    class SnsConfiguration
      include Validatable

      def initialize
        @protocol = 'sqs'
      end

      attr_accessor :endpoint, :protocol

      def validate
        errors << "#{@name}.protocol must be either sqs or cqs" unless %w(sqs cqs).include? protocol
      end
    end
  end
end
