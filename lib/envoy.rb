require 'aws-sdk-core'
require 'celluloid'
require 'middleware'
require 'nokogiri'
require 'securerandom'

require 'envoy/version'
require 'envoy/railtie'
require 'envoy/configuration'
require 'envoy/logging'
require 'envoy/supervision_group'
require 'envoy/environmental_name'
require 'envoy/sqs/queue'
require 'envoy/broker'
require 'envoy/dispatcher'
require 'envoy/fetcher'
require 'envoy/infrastructure_builder'
require 'envoy/sqs/message'
require 'envoy/worker'
require 'envoy/middlewares/worker'
require 'envoy/message_sanitizer'
require 'envoy/dead_letter_retrier'

module Envoy
  module_function

  def start!
    return if @started

    config.validate!

    Celluloid.logger = Logger.new STDOUT
    Celluloid.logger.level = Rails.logger.level
    Celluloid.logger.formatter = Rails.logger.formatter
    Celluloid.start

    pool_size = [2, config.queues.count].max

    @supervision_group = SupervisionGroup.new(pool_size, config.fetcher)
    @supervision_group.add_custom_actors config.celluloid.actors

    queues = [config.dead_letter_queue, config.queues].flatten.compact

    queues.each do |queue|
      @supervision_group.add_queue Envoy::SQS::Queue.new(queue, config.sqs.endpoint)
    end

    @started = true
  end

  def shutdown!
    return unless @started

    @supervision_group.stop

    Celluloid.shutdown
  end

  def configure
    yield config
  end

  def config
    @config ||= Configuration.new
  end
end
