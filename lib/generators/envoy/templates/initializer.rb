Envoy.configure do |config|

  # Define your AWS Credentials here, available symbols are:
  #
  # config.aws.credentials = { access_key_id: nil, secret_access_key: nil }

  # And region
  #
  # config.aws.region = 'eu-west-1'

  # Define the queues you wish to bind to. You should supply the queue name
  # as an underscored symbol, but you can also supply an options hash which
  # is passed directly to Aws::SQS::Client.new. See the documention on AWS
  # for available options.
  #
  # config.queues.add_queue(:the_queue_name, { endpoint: 'http://localhost:6059' })

  # The maximum number of concurrent workers and brokers running
  #
  # config.concurrency = 10

  # Mappings from queue name to message name to worker. Wildcard message names
  # are supported. If you intend to use the DeadLetterWorker you should add a
  # mapping from your dead letter queue.
  #
  # config.mappings = {
  #   dead_letters: { '*' => 'Envoy::DeadLetterWorker' },
  #   your_queue: { message_name: 'MyWorker' }
  # }

  # The broker class responsible for determining the mappings, this can be
  # overriden here, but you shouldn't need to.
  #
  # config.broker = MyBroker

  # The dispatcher is responsible for actually calling the processing of your
  # custom logic, again this can be overriden here, but in most situations you
  # shouldn't need to.
  #
  # config.dispatcher = MyDispatcher

  # Client actors are celluloid actors that can be inserted into the main
  # application loop. You can define them here as an array of classes that must
  # respond to a run() method.
  #
  # config.client_actors << MyActorClass

  # If you need to handle something specific within the SQS::Message lifecycle
  # then the message option provides several hook lambdas that are triggered when
  # it either dies, or is rendered unprocessable.
  #
  # config.messages.died          = ->(message) { Rails.logger.info "#{message.to_s} died"}
  # config.messages.unprocessable = ->(message) { Rails.logger.info "#{message.to_s} unprocessable"}
end
