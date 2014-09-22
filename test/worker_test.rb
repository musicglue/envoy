require 'test_helper'

describe Envoy::Worker do
  before do
    @mock_queue = MockQueue.new :queue_name
    @sqs_message = SQS_MESSAGE_HASH
    @mock_queue.push @sqs_message
    @packet = @mock_queue.pop(1).first
    @fetcher_id = SecureRandom.hex 4
    @message = Envoy::SQS::Message.new @packet, @mock_queue, @fetcher_id
  end

  describe 'working worker' do
    before do
      ::Worker.new(@message).safely_process
      sleep 1
    end

    it 'should process correctly and remove the message from the queue' do
      @mock_queue.get(@packet.receipt_handle).must_be_nil
    end
  end

  describe 'broken worker' do
    before do
      ::BrokenWorker.new(@message).safely_process
      sleep 1
    end

    it 'should error, and then make sure that the message still exists in the queue' do
      @mock_queue.get(@packet.receipt_handle).wont_be_nil
    end
  end
end
