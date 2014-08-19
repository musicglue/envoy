require 'ostruct'

class MockDispatcher
  include Celluloid

  def initialize
    @processed_messages = []
  end

  # def async
  #   self
  # end

  def process workflow_class, message
    @processed_messages << OpenStruct.new(workflow_class: workflow_class, message: message)
  end

  attr_reader :processed_messages
end
