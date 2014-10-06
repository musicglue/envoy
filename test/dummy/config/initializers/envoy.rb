Envoy.configure do |config|
  # AWS account configuration:

  config.aws.access_key = ENV['AWS_ACCESS_KEY']
  config.aws.secret_key = ENV['AWS_SECRET_KEY']
  config.aws.region = ENV['AWS_REGION']
  config.aws.account_id = ENV['AWS_ACCOUNT_ID']

  # SNS configuration:

  if Rails.env.development?
    config.sns.endpoint = "http://#{config.aws.region}.localhost:6061"
    config.sns.protocol = 'cqs'
  end

  # SQS configuration:

  if Rails.env.development?
    config.sqs.endpoint = "http://#{config.aws.region}.localhost:6059"
    config.sqs.protocol = 'cqs'
  end

  # Fetcher configuration:
  #
  #   config.fetcher.concurrent_messages_limit = 10

  # Callbacks configuration:
  #
  #   config.callbacks.message_died = ->(message) { ... }
  #   config.callbacks.message_unprocessable = ->(message) { ... }

  # Celluloid configuration:
  #
  #   config.celluloid.actors += [MyActor1, MyActor2]

  # Queue defaults configuration:
  #
  #   config.queue_defaults.delay_seconds = 0
  #   config.queue_defaults.message_retention_period = 1_209_600
  #   config.queue_defaults.visibility_timeout = 30
  #
  #   config.queue_defaults.redrive_policy.enabled = true
  #   config.queue_defaults.redrive_policy.max_receive_count = 10

  config.queue_defaults.redrive_policy.dead_letter_queue = 'dead_letters'

  # Subscription defaults configuration:
  #
  #   config.subscription_defaults.raw_message_delivery = true

  # Queue configuration:

  config.add_dead_letter_queue 'dead_letters'

  config.add_queue('important_events_queue') do |_queue, subscriptions|
    subscriptions.add 'something_happened', 'MyWorker'
  end

  config.add_queue('unimportant_events_queue') do |queue, subscriptions|
    queue.redrive_policy.enabled = false
    subscriptions.add 'something_else_happened', 'MyOtherWorker'
  end
end
