require 'ostruct'

class MockQueue
  attr_reader :queue, :queue_name

  def initialize(queue_name, _options = {})
    @queue_name = [queue_name.to_s.dasherize, Envoy.env].join('-')
    @queue = []
    @read_messages = []
  end

  def get(handle)
    @read_messages.find { |x| x.receipt_handle == handle }
  end

  def push(message)
    @queue << package(message)
  end

  def pop(count)
    messages = @queue.shift(count)
    @read_messages.push(*messages)
    messages
  end

  def extend_invisibility(handle, _time)
    delete_message(handle)
  end

  def delete_message(handle)
    @read_messages.reject! { |x| x.receipt_handle == handle }
  end

  def package(message)
    OpenStruct.new(
                     message_id:  UUID.generate,
                     body:        message.to_json,
                     md5_of_body: Digest::MD5.hexdigest(message.to_json),
                     md5_of_message_attributes: nil,
                     message_attributes: {},
                     attributes:  {
                       'SenderId'      => UUID.generate,
                       'SentTimestamp' =>  Time.now,
                       'ApproximateFirstReceiveTimestamp' => Time.now,
                       'ApproximateReceiveCount' => 1
                     },
                     receipt_handle: UUID.generate
                   )
  end
end
