require 'ostruct'

class MockQueue
  attr_reader :queue, :queue_name, :mappings

  def initialize(queue_name, mappings = {})
    @queue_name = queue_name
    @queue = []
    @read_messages = []
    @mappings = mappings
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
      message_id:  SecureRandom.uuid,
      body:        message.to_json,
      md5_of_body: Digest::MD5.hexdigest(message.to_json),
      md5_of_message_attributes: nil,
      message_attributes: {},
      attributes:  {
        'SenderId'      => SecureRandom.uuid,
        'SentTimestamp' =>  Time.now,
        'ApproximateFirstReceiveTimestamp' => Time.now,
        'ApproximateReceiveCount' => 1
      },
      receipt_handle: SecureRandom.uuid
    )
  end
end