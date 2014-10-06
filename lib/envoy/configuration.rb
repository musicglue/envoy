require_relative 'configuration/validatable'
require_relative 'configuration/aws_configuration'
require_relative 'configuration/callbacks_configuration'
require_relative 'configuration/celluloid_configuration'
require_relative 'configuration/dead_letter_queue_configuration'
require_relative 'configuration/dead_letter_queue_subscription_configuration'
require_relative 'configuration/fetcher_configuration'
require_relative 'configuration/queue_configuration'
require_relative 'configuration/redrive_policy_configuration'
require_relative 'configuration/sns_configuration'
require_relative 'configuration/sqs_configuration'
require_relative 'configuration/subscription_configuration'

module Envoy
  class Configuration
    include Validatable

    def initialize
      @aws = AwsConfiguration.new
      @callbacks = CallbacksConfiguration.new
      @celluloid = CelluloidConfiguration.new
      @dead_letter_queue = nil
      @fetcher = FetcherConfiguration.new
      @queue_defaults = QueueConfiguration.new 'queue_defaults'
      @sns = SnsConfiguration.new
      @sqs = SqsConfiguration.new
      @subscription_defaults = SubscriptionConfiguration.new 'subscription_defaults'
      @queues = {}
    end

    attr_reader :aws,
                :callbacks,
                :celluloid,
                :dead_letter_queue,
                :fetcher,
                :queue_defaults,
                :sns,
                :sqs,
                :subscription_defaults

    def validate
      [aws, celluloid, fetcher, queue_defaults, sns, sqs].each do |section|
        section.valid?
        errors.push *(section.errors)
      end

      if dead_letter_queue
        dead_letter_queue.valid?
        errors.push *(dead_letter_queue.errors)
      end
    end

    def validate!
      update_aws

      return if valid?

      fail %(Invalid configuration: \n\n#{errors.join("\n")}\n\n)
    end

    def add_dead_letter_queue name
      fail 'Dead letter queue already configured.' if @dead_letter_queue

      queue = DeadLetterQueueConfiguration.new name
      @queue_defaults.copy_onto queue
      yield queue if block_given?
      @dead_letter_queue = queue
    end

    def add_queue name
      queue = QueueConfiguration.new name
      @queue_defaults.copy_onto queue
      subscription_defaults.copy_onto queue.subscriptions
      yield queue, queue.subscriptions if block_given?
      @queues[name] = queue
    end

    def queues
      @queues.values
    end

    def get_queue name
      if @dead_letter_queue && @dead_letter_queue.name == name
        @dead_letter_queue
      else
        @queues[name]
      end
    end

    def update_aws
      Aws.config[:credentials] = Aws::Credentials.new aws.access_key, aws.secret_key
      Aws.config[:region] = aws.region
    end
  end
end
