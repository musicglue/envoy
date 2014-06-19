require 'active_support'
require 'active_support/core_ext'

module Envoy
  VERSION = '1.0.0'
  ROOT_PATH = File.dirname(File.dirname(__FILE__))

  module_function

  def start!
    return if @started
    Celluloid.start
    AssetRefinery::Application.run!
    fetchers.each {|x| x.run }
    @started = true
  end

  def config
    @config ||= ActiveSupport::OrderedOptions.new.tap do |x|
      x.credentials = {
        access_key_id: nil,
        secret_access_key: nil }
      x.queues      = QueueManager.new
      x.concurrency = 10
      x.mappings    = {}
      x.broker      = Envoy::Broker
      x.dispatcher  = Envoy::Dispatcher
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

  private

    def split_concurrency
      config.concurrency / config.queues.count
    end
end
