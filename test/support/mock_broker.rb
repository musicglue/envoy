class MockBroker
  include Celluloid

  attr_reader :processed_messages

  def initialize
    @processed_messages = []
  end

  def process_message message, queue
    @processed_messages << OpenStruct.new(message: message, queue: queue)
  end
end
