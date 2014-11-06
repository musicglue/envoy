require_relative '../test_helper'

describe Envoy::Watchdog do
  before do
    config = Envoy::Configuration.new
    config.add_queue 'watchdog_test'

    @queue_config = config.get_queue 'watchdog_test'
    @queue_config.message_heartbeat_interval = 0.5

    payload = {
      headers: {
        id: SecureRandom.uuid,
        type: 'type-1'
      },
      body: {}
    }

    @message = Envoy::ReceivedMessage.new SecureRandom.uuid, SecureRandom.uuid, 'watchdog_test', payload
    @queue = StubQueue.new 'watchdog_test', StubSqs.new, config
  end

  def create_watchdog
    described_class.new(
      sqs_id: @message.sqs_id,
      message_topics: @queue.message_topics,
      worker: @worker,
      queue_config: @queue_config)
  end

  describe 'the worker assigned to the message succeeds' do
    before do
      @worker = FastSucceedingWorker.new @message
      @watchdog = create_watchdog
    end

    it 'publishes a message_processed event' do
      @watchdog.process
      sleep 0.2
      @queue.acknowledged_messages.must_include @message.sqs_id
    end
  end

  describe 'the worker assigned to the message fails' do
    before do
      @worker = FastFailingWorker.new @message
      @watchdog = create_watchdog
    end

    it 'publishes a message_failed event' do
      @watchdog.process
      sleep 0.2
      @queue.unacknowledged_messages.must_include @message.sqs_id
    end
  end

  describe 'the worker assigned to the message succeeds after a heartbeat' do
    before do
      @worker = SlowSucceedingWorker.new @message
      @watchdog = create_watchdog
    end

    it 'publishes a message_heartbeat event' do
      @watchdog.process
      sleep 1.2
      @queue.message_heartbeats.must_include @message.sqs_id
      @queue.acknowledged_messages.must_include @message.sqs_id
    end
  end

  describe 'the watchdog is terminated while the worker is still running' do
    before do
      @worker = SlowSucceedingWorker.new @message
      @watchdog = create_watchdog
    end

    it 'does not raise any errors' do
      Celluloid.shutdown_timeout = 0.1

      @watchdog.process

      begin
        Celluloid.shutdown
      rescue => e
        @error = e
      end

      @error.must_be_nil
    end
  end
end
