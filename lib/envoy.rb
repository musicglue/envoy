require 'active_support/concern'
require 'active_support/core_ext/module/delegation'
require 'aws-sdk-core'
require 'celluloid'
require 'middleware'
require 'nokogiri'
require 'securerandom'

require 'envoy/version'
require 'envoy/logging'
require 'envoy/active_record'
require 'envoy/configuration'
require 'envoy/environmental_name'
require 'envoy/message'
require 'envoy/message_sanitizer'
require 'envoy/dead_letter_retrier'
require 'envoy/infrastructure_builder'
require 'envoy/sqs'
require 'envoy/router'
require 'envoy/queue/register'
require 'envoy/queue'
require 'envoy/middleware'
require 'envoy/middlewares/worker'
require 'envoy/worker'
require 'envoy/watchdog/message_topics'
require 'envoy/watchdog'
require 'envoy/supervision_group'
require 'envoy/railtie'

module Envoy
  module_function

  def config
    @config ||= Configuration.new
  end

  def configure
    yield config
  end

  def start
    return if @running
    @running = true

    setup_logger
    config.validate!

    Celluloid.log_actor_crashes = false
    Celluloid.shutdown_timeout = 1
    Celluloid.start

    attrs = {}
    attrs[:endpoint] = config.sqs.endpoint unless config.sqs.endpoint.blank?

    sqs = Envoy::Sqs.new Aws::SQS::Client.new attrs

    @group = Envoy::SupervisionGroup.new config, sqs
    @group.start
  end

  def stop
    return unless @running
    @running = false

    @group.stop

    Celluloid.shutdown
  end

  def setup_logger
    level = (Logger.const_get ENV['ENVOY_LOG_LEVEL'].to_s.upcase) rescue Rails.logger.level

    Celluloid.logger = Logger.new STDOUT
    Celluloid.logger.level = level
    Celluloid.logger.formatter = Rails.logger.formatter
  end
end
