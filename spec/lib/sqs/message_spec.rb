require 'spec_helper'
require 'pry'

describe Envoy::SQS::Message do

  let(:sqs_message)     { SQS_MESSAGE_HASH }
  let(:mock_queue)      { MockQueue.new(:queue_name) }
  let(:fetcher_id)      { SecureRandom.hex(4) }
  let(:described_class) { Envoy::SQS::Message.new(packet, mock_queue, fetcher_id) }

  before do
    mock_queue.push sqs_message
  end

  describe 'with a valid packet' do

    let(:packet) { mock_queue.pop(1).first }

    it 'should return the header' do
      described_class.header.type.must_equal SQS_MESSAGE_HASH['header']['type']
    end

    it 'should return the body' do
      described_class.body.to_h.must_equal SQS_MESSAGE_HASH['body'].symbolize_keys
    end

    it 'should declare its type' do
      described_class.type.must_equal SQS_MESSAGE_HASH['header']['type'].to_sym
    end

    it 'when executing a heartbeat will prevent it from being picked off the queue again' do
      described_class.heartbeat
      mock_queue.pop(1).first.must_be_nil
    end

  end

  describe 'with an invalid packet' do
    let(:sqs_message)   { 'oops' }
    let(:packet)        { mock_queue.pop(1).first }

    it 'should mark the message as unprocessable' do
      described_class
      sleep(0.1)
      mock_queue.pop(1).first.must_be_nil
    end

  end

end
