module Envoy
  class DeadLetterRetrier
    def initialize
      @sanitizer = MessageSanitizer.new
    end

    def retry scope
      return if scope.count == 0

      scope.each do |message|
        hash = message.message
        hash = @sanitizer.sanitize hash
        topic = hash['header']['type'].underscore.to_sym

        Docket.topics[topic].publish hash.to_json

        message.delete
      end
    end
  end
end
