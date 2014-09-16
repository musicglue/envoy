require 'nokogiri'
require 'active_support'
require 'active_support/core_ext'
require 'aws-sdk-core'
require 'celluloid'
require 'uuid'
require 'ostruct'
require 'middleware'
require 'newrelic_rpm'

require 'envoy/logging'
require 'envoy/queue_name'
require 'envoy/sqs/message'
require 'envoy/sqs/queue'

require 'envoy/broker/map'
require 'envoy/broker'
require 'envoy/dispatcher'
require 'envoy/fetcher'
require 'envoy/queue_directory'
require 'envoy/middlewares/worker'
require 'envoy/logging'
require 'envoy/dead_letter_retrier'

require 'envoy/worker'
require 'envoy/railtie' if defined? Rails

module Envoy
  VERSION = '1.0.2'
  ROOT_PATH = File.dirname(File.dirname(__FILE__))

  module_function

  def shutdown!
    return unless @started

    config.client_actors.each do |supervisor|
      supervisor.actors.each do |actor|
        actor.respond_to?(:stop) ? actor.stop : actor.terminate
      end
    end

    fetchers.each do |supervisor|
      supervisor.actors.each &:stop
    end

    Celluloid.shutdown
  end

  def start!
    return if @started

    require 'envoy/application'

    Celluloid.start
    Envoy::Application.run!

    fetchers.each do |supervisor|
      supervisor.actors.each do |actor|
        actor.async.run
      end
    end

    config.client_actors.map! &:supervise

    config.client_actors.each do |supervisor|
      supervisor.actors.each do |actor|
        actor.async.run
      end
    end

    @started = true
  end

  def config
    @config ||= ActiveSupport::OrderedOptions.new.tap do |x|
      x.aws = ActiveSupport::OrderedOptions.new.tap do |aws|
        aws.credentials = {
          access_key_id: nil,
          secret_access_key: nil }
        aws.region    = 'eu-west-1'
      end
      x.queues        = QueueDirectory.new
      x.concurrency   = 10
      x.mappings      = {}
      x.broker        = Broker
      x.dispatcher    = Dispatcher
      x.queue         = SQS::Queue
      x.client_actors = []
      x.messages      = ActiveSupport::OrderedOptions.new.tap do |m|
        m.died          = ->(_message) {}
        m.unprocessable = ->(_message) {}
      end
    end
  end

  def fetchers
    @fetchers ||= config.queues.map do |queue|
      Fetcher.supervise config.concurrency, broker, queue
    end
  end

  def broker
    Celluloid::Actor[:broker_pool]
  end

  def dispatcher
    Celluloid::Actor[:dispatcher_pool]
  end

  def credentials
    @credentials ||= Aws::Credentials.new(config.aws.credentials[:access_key_id],
                                          config.aws.credentials[:secret_access_key])
  end

  def configure &_block
    yield(config)
  end

  def env
    (ENV['RACK_ENV'] || ENV['RAILS_ENV'] || ENV['ENVOY_ENV'] || 'development').inquiry
  end

  def pool_count
    config.queues.count < 2 ? 2 : config.queues.count
  end
end
