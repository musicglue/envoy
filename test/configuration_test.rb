require_relative 'test_helper'
require_relative '../lib/envoy'

describe Envoy::Configuration do
  before do
    @config = described_class.new
    @valid = @config.valid?
  end

  def assert_error error
    @config.errors.must_include error
  end

  describe 'AWS' do
    it 'expects an access key' do
      assert_error 'aws.access_key is required'
    end

    it 'expects a secret key' do
      assert_error 'aws.secret_key is required'
    end

    it 'expects a region' do
      assert_error 'aws.region is required'
    end

    it 'expects an account id' do
      assert_error 'aws.account_id is required'
    end
  end

  describe 'fetcher' do
    it 'expects a concurrent_messages_limit' do
      @config.fetcher.concurrent_messages_limit = 0
      @config.valid?
      assert_error 'fetcher.concurrent_messages_limit must be an integer >= 1'
    end
  end

  describe 'celluloid' do
    it 'expects an actors to be an array' do
      @config.celluloid.actors = 'blah'
      @config.valid?
      assert_error 'celluloid.actors must be an array'
    end

    it 'expects an array of Celluloid classes' do
      @config.celluloid.actors += [Integer]
      @config.valid?
      assert_error 'celluloid.actors may only contain classes that include Celluloid'
    end
  end

  describe 'queue_defaults' do
    it 'has a default delay_seconds of 0' do
      @config.queue_defaults.delay_seconds.must_equal 0
    end

    it 'expects a delay_seconds in the range 0-900' do
      @config.queue_defaults.delay_seconds = 901
      @config.valid?
      assert_error 'queue_defaults.delay_seconds must be in the range 0..900'
    end

    it 'has a default message_retention_period of 1209600' do
      @config.queue_defaults.message_retention_period.must_equal 1_209_600
    end

    it 'expects a message_retention_period in the range 60-1209600' do
      @config.queue_defaults.message_retention_period = 59
      @config.valid?
      assert_error 'queue_defaults.message_retention_period must be in the range 60..1209600'
    end

    it 'has a default visibility_timeout of 30' do
      @config.queue_defaults.visibility_timeout.must_equal 30
    end

    it 'expects a visibility_timeout in the range 0-43200' do
      @config.queue_defaults.visibility_timeout = 43_201
      @config.valid?
      assert_error 'queue_defaults.visibility_timeout must be in the range 0..43200'
    end

    describe 'redrive policy' do
      it 'is enabled by default' do
        @config.queue_defaults.redrive_policy.enabled.must_equal true
      end

      it 'has a default max_receive_count of 10' do
        @config.queue_defaults.redrive_policy.max_receive_count.must_equal 10
      end

      it 'expects a max_receive_count in the range 1-1000' do
        @config.queue_defaults.redrive_policy.max_receive_count = 0
        @config.valid?
        assert_error 'queue_defaults.redrive_policy.max_receive_count must be in the range 1..1000'
      end

      it 'has no dead letter queue name by default' do
        @config.queue_defaults.redrive_policy.dead_letter_queue.must_be_nil
      end

      it 'expects a dead_letter_queue to be supplied' do
        assert_error 'queue_defaults.redrive_policy.dead_letter_queue is required'
      end
    end
  end

  describe 'subscription_defaults' do
    it 'enables raw_message_delivery by default' do
      @config.subscription_defaults.raw_message_delivery.must_equal true
    end
  end

  describe 'adding a dead letter queue' do
    describe 'defaults' do
      before do
        @name = 'dlq'

        @config.add_dead_letter_queue(@name) do |queue, _subscriptions|
          queue.delay_seconds = 899
        end

        @queue = @config.dead_letter_queue
      end

      it 'exists in the queue list' do
        @queue.wont_be_nil
      end

      it "can have it's default settings overridden" do
        @queue.delay_seconds.must_equal 899
      end

      it 'is valid' do
        @queue.must_be :valid?
      end
    end
  end

  describe 'adding a redriven queue' do
    describe 'defaults' do
      before do
        @name = 'redriven-queue'

        @config.add_queue(@name) do |queue, _subscriptions|
          queue.redrive_policy.dead_letter_queue = 'dlq'
        end

        @queue = @config.get_queue @name
      end

      it 'exists in the queue list' do
        @queue.wont_be_nil
      end

      it "has it's redrive policy enabled" do
        @queue.redrive_policy.enabled.must_equal true
      end

      it 'records the dead letter queue to use for failing messages' do
        @queue.redrive_policy.dead_letter_queue.must_equal 'dlq'
      end
    end

    describe 'without a dead letter queue defined' do
      before do
        @name = 'invalid_queue'
        @config.add_queue(@name)
        @queue = @config.get_queue @name
      end

      it 'expects a dead letter queue to be named' do
        @queue.valid?.must_equal false
        @queue.errors.must_include 'invalid_queue.redrive_policy.dead_letter_queue is required'
      end
    end
  end

  describe 'queues created after changing the defaults' do
    before do
      @config.queue_defaults.visibility_timeout = 31
      @config.queue_defaults.redrive_policy.max_receive_count = 5

      @name = 'new_queue'
      @config.add_queue(@name)
      @queue = @config.get_queue @name
    end

    it 'uses the new defaults' do
      @queue.visibility_timeout.must_equal 31
      @queue.redrive_policy.max_receive_count.must_equal 5
    end
  end

  describe 'adding subscriptions' do
    before do
      @name1 = 'subscriber1'
      @config.add_queue(@name1) do |_queue, subscriptions|
        subscriptions.add 'thing_happened', 'MyWorker1'
      end
      @queue1 = @config.get_queue @name1

      @name2 = 'subscriber2'
      @config.add_queue(@name2) do |_queue, subscriptions|
        subscriptions.add 'thing_happened', 'MyWorker2'
        subscriptions.add 'other_thing_happened', 'MyOtherWorker'
      end
      @queue2 = @config.get_queue @name2
    end

    # it 'lists only unique topic names in the topics list' do
    #   @config.topics.keys.count.must_equal 2
    #   @config.topics.keys.must_include 'thing_happened'
    #   @config.topics.keys.must_include 'other_thing_happened'
    # end
  end
end
