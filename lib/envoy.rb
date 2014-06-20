require 'active_support'
require 'active_support/core_ext'
require 'celluloid'
require 'uuid'

require 'envoy/sqs/message'
require 'envoy/sqs/queue'

require 'envoy/broker'
require 'envoy/dispatcher'
require 'envoy/fetcher'
require 'envoy/queue_directory'

module Envoy
  VERSION = '1.0.0'
  ROOT_PATH = File.dirname(File.dirname(__FILE__))

  module_function

  def start!
    return if @started
    require 'envoy/application'
    Celluloid.start
    AssetRefinery::Application.run!
    fetchers.each {|x| x.run }
    config.client_actors.each {|x| x.run }
    @started = true
  end

  def config
    @config ||= ActiveSupport::OrderedOptions.new.tap do |x|
      x.credentials = {
        access_key_id: nil,
        secret_access_key: nil }
      x.queues        = QueueDirectory.new
      x.concurrency   = 10
      x.mappings      = {}
      x.broker        = Broker
      x.dispatcher    = Dispatcher
      x.client_actors = []
      x.messages      = ActiveSupport::OrderedOptions.new.tap do |m|
        m.died          = ->(message) {}
        m.unprocessable = ->(message) {}
      end
    end
  end

  def fetchers
    @fetchers ||= config.queues.map {|queue| Fetcher.new(split_concurrency, broker, queue) }
  end

  def credentials
    @credentials ||= Aws::Credentials.new(config.credentials[:access_key_id], config.credentials[:secret_access_key])
  end

  def configure &block
    yield(config)
  end

  def env
    (ENV['RACK_ENV'] || ENV['RAILS_ENV'] || ENV['ENVOY_ENV'] || 'development').inquiry
  end

  private

    def split_concurrency
      config.concurrency / config.queues.count
    end
end
