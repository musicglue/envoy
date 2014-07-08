class MockBroker
  include Celluloid

  attr_reader :processed_messages
  def initialize
    @processed_messages = []
  end

  def process_message(message)
    @processed_messages << message
  end
end
