class MockDispatcher
  include Celluloid

  def initialize
    @processed_messages = []
  end

  def process worker_class, message
    @processed_messages << OpenStruct.new(worker_class: worker_class, message: message)
  end

  attr_reader :processed_messages
end
