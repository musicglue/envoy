require 'test_helper'

describe Envoy::Broker do
  class ::Worker1; end
  class ::Worker2; end
  class ::Worker3; end

  class Envoy::DeadLetterWorker; end

  before do
    @dispatcher = MockDispatcher.new

    @broker = Envoy::Broker.new
    @broker.dispatcher = @dispatcher

    @message_1 = OpenStruct.new type: :message_1, log_data: {}
    @message_2 = OpenStruct.new type: :message_2, log_data: {}

    config = Envoy::Configuration::QueueConfiguration.new 'queue_1'
    config.subscriptions.add 'message_1', 'Worker1'
    config.subscriptions.add 'message_2', 'Worker2'

    @queue_1 = MockQueue.new 'queue_1', config

    config = Envoy::Configuration::QueueConfiguration.new 'queue_2'
    config.subscriptions.add 'message_1', Worker3

    @queue_2 = MockQueue.new 'queue_2', config

    config = Envoy::Configuration::DeadLetterQueueConfiguration.new 'queue_3'

    @queue_3 = MockQueue.new 'queue_3', config
  end

  let(:worker_class) { @dispatcher.processed_messages.first.worker_class }
  let(:process_message) { @dispatcher.processed_messages.first.message }

  describe 'message_1 received from queue_1' do
    it 'is delivered to Worker1' do
      @broker.process_message @message_1, @queue_1

      worker_class.must_equal ::Worker1
      process_message.must_equal @message_1
    end
  end

  describe 'message_2 received from queue_1' do
    it 'is delivered to Worker2' do
      @broker.process_message @message_2, @queue_1

      worker_class.must_equal ::Worker2
      process_message.must_equal @message_2
    end
  end

  describe 'message_1 received from queue_2' do
    it 'is delivered to Worker3' do
      @broker.process_message @message_1, @queue_2

      worker_class.must_equal ::Worker3
      process_message.must_equal @message_1
    end
  end

  describe 'message_1 received from queue_3' do
    it 'is delivered to the dead letter worker' do
      @broker.process_message @message_1, @queue_3

      worker_class.must_equal Envoy::DeadLetterWorker
      process_message.must_equal @message_1
    end
  end

  describe 'message_2 received from queue_3' do
    it 'is delivered to the dead letter worker' do
      @broker.process_message @message_2, @queue_3

      worker_class.must_equal Envoy::DeadLetterWorker
      process_message.must_equal @message_2
    end
  end
end
