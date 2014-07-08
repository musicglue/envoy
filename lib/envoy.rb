require 'active_support'
require 'active_support/core_ext'
require 'aws-sdk-core'
require 'celluloid'
require 'uuid'
require 'ostruct'

require 'envoy/sqs/message'
require 'envoy/sqs/queue'

require 'envoy/broker'
require 'envoy/dispatcher'
require 'envoy/fetcher'
require 'envoy/queue_directory'

require 'envoy/worker'
require 'envoy/railtie' if defined? Rails

module Envoy
  VERSION = '1.0.0'
  ROOT_PATH = File.dirname(File.dirname(__FILE__))

  module_function

  def shutdown!
    return unless @started
    fetchers.each { |x| x.stop }
    config.client_actors.each { |x| x.respond_to?(:stop) ? x.stop : x.terminate }
    Celluloid.shutdown
  end

  def start!
    return if @started
    require 'envoy/application'
    Celluloid.start
    Envoy::Application.run!
    fetchers.each { |x| x.async.run }
    config.client_actors.map!(&:new)
    config.client_actors.each { |x| x.async.run }
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
    @fetchers ||= config.queues.map { |queue| Fetcher.new(split_concurrency, broker, queue) }
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

  def split_concurrency
    config.concurrency
  end
end
