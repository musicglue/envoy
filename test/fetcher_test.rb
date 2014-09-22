require 'test_helper'

describe Envoy::Fetcher do
  let(:message_hash)    { SQS_MESSAGE_HASH }
  let(:mock_queue)      { MockQueue.new(:queue_name) }
  let(:mock_broker)     { MockBroker.new }
  let(:described_class) { Envoy::Fetcher.new(1, mock_broker, mock_queue) }

  describe 'while fetching a message' do

    before do
      mock_queue.push message_hash
      described_class.fetch
    end

    it 'should send a message to the broker' do
      mock_broker.processed_messages.wont_be_empty
    end

    it 'should decrement the number of available slots' do
      described_class.send(:available_slots?).must_equal false
    end

    describe 'after processing' do

      let(:processed_message) { mock_broker.processed_messages.first.message }
      let(:source_queue) { mock_broker.processed_messages.first.queue }

      it 'notifies the broker which queue was the source of the message' do
        source_queue.must_equal mock_queue
      end

      describe 'successfully' do

        before do
          processed_message.complete
          sleep(0.1) # Due to the Async nature of the complete call
        end

        it 'should free the slot' do
          described_class.send(:available_slots?).must_equal true
        end

      end

      describe 'unprocessable' do

        before do
          processed_message.unprocessable
          sleep(0.1)
        end

        it 'should free the slot' do
          described_class.send(:available_slots?).must_equal true
        end

      end

      describe 'unsuccesfully' do

        before do
          processed_message.died
          sleep(0.1)
        end

        it 'should free the slot' do
          described_class.send(:available_slots?).must_equal true
        end

      end

    end

    it 'should stop gracefully' do
      described_class.stop
      described_class.alive?.must_equal false
    end

  end

  describe 'limited message slots' do

    before do
      10.times { mock_queue.push message_hash }
      described_class.fetch
    end

    it 'should only process as many messages as slots allow' do
      mock_broker.processed_messages.count.must_equal 1
    end

    it 'should free a slot and process again' do
      mock_broker.processed_messages.first.message.complete
      sleep 0.1
      described_class.fetch
      mock_broker.processed_messages.count.must_equal 2
    end

  end

end
