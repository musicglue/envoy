require 'test_helper'

describe Envoy::SQS::Message do
  let(:sqs_message)     { SQS_MESSAGE_HASH }
  let(:mock_queue)      { MockQueue.new(:queue_name, Envoy::Configuration::QueueConfiguration.new('abc')) }
  let(:fetcher_id)      { SecureRandom.hex(4) }
  let(:described_class) { Envoy::SQS::Message.new(packet, mock_queue, fetcher_id) }

  before do
    mock_queue.push sqs_message
  end

  describe 'with a valid packet' do

    let(:packet) { mock_queue.pop(1).first }

    it 'should return the header as a hash' do
      described_class.header.is_a?(Hash).must_equal true
    end

    it 'should return the body as a hash' do
      described_class.body.is_a?(Hash).must_equal true
    end

    it 'should return the whole header accessible using strings or keys' do
      hash = described_class.header

      SQS_MESSAGE_HASH['header'].each do |key, value|
        hash[key.to_s].must_equal value
        hash[key.to_sym].must_equal value
      end
    end

    it 'should return the whole body accessible using strings or keys' do
      hash = described_class.body

      SQS_MESSAGE_HASH['body'].each do |key, value|
        hash[key.to_s].must_equal value
        hash[key.to_sym].must_equal value
      end
    end

    it 'should declare its type' do
      described_class.type.must_equal SQS_MESSAGE_HASH['header']['type'].to_sym
    end

    it 'when executing a heartbeat will prevent it from being picked off the queue again' do
      described_class.heartbeat
      mock_queue.pop(1).first.must_be_nil
    end

    it 'should be possible to use the headers method as an alias for header' do
      key = SQS_MESSAGE_HASH['header'].keys.sample

      described_class.headers[key].must_equal SQS_MESSAGE_HASH['header'][key]
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
