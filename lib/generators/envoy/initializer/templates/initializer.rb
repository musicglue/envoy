Envoy.configure do |_config|

  # Define your AWS Credentials here, available symbols are:
  # config.aws.credentials = { access_key_id: nil, secret_access_key: nil }

  # And region
  # config.aws.region = 'eu-west-1'

  # Define the queues you wish to bind to
  # config.queues is an instance of Envoy::QueueDirectory, that provides an add_queue method, you should supply the queue name
  # as an underscored symbol
  #
  # Add queue takes a name and an options hash, the options hash is passed directly to Aws.sqs, please see
  # documention on AWS for usage of the Aws.sqs class

  # config.queues.add_queue(:the_queue_name, { endpoint: 'http://localhost:6059' })

  # The maximum number of concurrent workers and brokers running
  # config.concurrency = 10

  # Mapping for message types to message processing classes, in order to provide a processing class
  # the Dispatcher will call [message_type] and then constantize the string, and then call perform(Envoy::SQS::Message)
  # config.mappings = {
  #   message_name: 'MyProcessor'
  # }

  # The broker class responsible for determining the mappings, this can be overriden here, but you shouldn't need to
  # config.broker = MyBroker

  # The dispatcher is responsible for actually calling the processing of your custom logic, again
  # this can be overriden here, but in most situations you shouldn't need to
  # config.dispatcher = MyDispatcher

  # Client actors are celluloid actors that can be inserted into the main application loop.
  # You can define them here as an array of classes that must respond to a run() method.
  # config.client_actors << MyActorClass

  # If you need to handle something specific within the SQS::Message lifecycle then the message option provides
  # several hook lambdas that are triggered when it either dies, or is rendered unprocessable
  # config.messages.died          = ->(message) { Rails.logger.info "#{message.to_s} died"}
  # config.messages.unprocessable = ->(message) { Rails.logger.info "#{message.to_s} unprocessable"}

end
