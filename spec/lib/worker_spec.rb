require_relative '../spec_helper'
require 'pry'

describe Envoy::Worker do

  let(:mock_queue)    { MockQueue.new(:queue_name) }
  let(:sqs_message)   { SQS_MESSAGE_HASH }
  let(:packet)        { mock_queue.pop(1).first }
  let(:fetcher_id)    { SecureRandom.hex(4) }
  let(:message_class) { Envoy::SQS::Message.new(packet, mock_queue, fetcher_id) }

  before do
    mock_queue.push sqs_message
  end

  describe 'A working worker' do

    let(:worker)        { Worker.new(message_class) }

    before do
      worker.safely_process
    end

    it 'should process correctly and remove the message from the queue' do
      mock_queue.get(packet.receipt_handle).must_be_nil
    end

  end

  # describe 'A broken worker' do

  #   let(:worker)  { BrokenWorker.new(message_class) }

  #   before do
  #     worker.safely_process
  #   end

  #   it 'should error, and then make sure that the message still exists in the queue' do
  #     mock_queue.get(packet.receipt_handle).wont_be_nil
  #   end

  # end

end
