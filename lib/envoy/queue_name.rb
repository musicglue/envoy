module Envoy
  class QueueName
    def initialize name
      @name = [name.to_s.dasherize, Envoy.env].join('-')
    end

    def to_s
      @name
    end
  end
end
