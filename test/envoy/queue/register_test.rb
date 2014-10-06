require_relative '../../test_helper'

describe Envoy::Queue::Register do
  def build_message
    payload = {
      headers: {
        id: SecureRandom.uuid,
        type: 'type-1'
      },
      body: {}
    }

    Envoy::Message.new SecureRandom.uuid, SecureRandom.uuid, 'queue-name', payload
  end

  before do
    @register = described_class.new 2

    @message_1 = build_message
    @watchdog_1 = {}
    @message_2 = build_message
    @watchdog_2 = {}
    @message_3 = build_message
    @watchdog_3 = {}
  end

  describe 'when a message/watchdog pair is added' do
    before do
      @register.add @message_1, @watchdog_1
    end

    it 'has a free size of 1' do
      @register.free.must_equal 1
    end
  end

  describe 'when a two messages are added' do
    before do
      @register.add @message_1, @watchdog_1
      @register.add @message_2, @watchdog_2
    end

    it 'has a free size of 0' do
      @register.free.must_equal 0
    end

    it 'can find both messages by id' do
      @register[@message_1.sqs_id].message.must_equal @message_1
      @register[@message_1.sqs_id].watchdog.must_equal @watchdog_1
      @register[@message_2.sqs_id].message.must_equal @message_2
      @register[@message_2.sqs_id].watchdog.must_equal @watchdog_2
    end
  end

  describe 'when a three messages are added' do
    before do
      @register.add @message_1, @watchdog_1
      @register.add @message_2, @watchdog_2
      @register.add @message_3, @watchdog_3
    end

    it 'has a free size of 0' do
      @register.free.must_equal 0
    end

    it 'can find all three messages by sqs_id' do
      @register[@message_1.sqs_id].message.must_equal @message_1
      @register[@message_1.sqs_id].watchdog.must_equal @watchdog_1
      @register[@message_2.sqs_id].message.must_equal @message_2
      @register[@message_2.sqs_id].watchdog.must_equal @watchdog_2
      @register[@message_3.sqs_id].message.must_equal @message_3
      @register[@message_3.sqs_id].watchdog.must_equal @watchdog_3
    end
  end

  describe 'when two messages are added and one is removed' do
    before do
      @register.add @message_1, @watchdog_1
      @register.add @message_2, @watchdog_2
      @removed = @register.remove @message_1.sqs_id
    end

    it 'has a free size of 1' do
      @register.free.must_equal 1
    end

    it 'cannot find the removed message by sqs_id' do
      @register[@message_1.sqs_id].must_be_nil
    end

    it 'can find the unremoved message by sqs_id' do
      @register[@message_2.sqs_id].message.must_equal @message_2
      @register[@message_2.sqs_id].watchdog.must_equal @watchdog_2
    end

    it 'returned the entry when it was removed' do
      @removed.message.must_equal @message_1
      @removed.watchdog.must_equal @watchdog_1
    end
  end
end
