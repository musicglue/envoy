module Envoy
  class DeadLetterRetrier
    def initialize
      @publisher = Envoy::MessagePublisher.new
    end

    def retry scope
      return if scope.count == 0

      count = 0
      scope.each do |message|
        count += 1
        @publisher.publish message.message
        message.delete
      end

      puts "Retried #{count} dead letter(s)."
    end
  end
end
