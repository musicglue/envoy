module Envoy
  class Watchdog
    include Celluloid
    include Celluloid::Notifications

    trap_exit :worker_failed

    def initialize(
      sqs_id:,
      message_topics:,
      worker:,
      callbacks_config: Envoy::Configuration::CallbacksConfiguration.new,
      queue_config: Envoy::Configuration::QueueConfiguration.new('default'))
      @sqs_id = sqs_id
      @message_topics = message_topics
      @worker = worker
      @worker_class = worker.class
      @callbacks = callbacks_config
      @heartbeat_interval = queue_config.message_heartbeat_interval
      @error = nil
    end

    def process
      @timer = every(@heartbeat_interval) do
        begin
          async.publish @message_topics.heartbeat, @sqs_id
        rescue Celluloid::DeadActorError
        end
      end

      @topic = @message_topics.failure

      begin
        @worker.future.process_for_watchdog.value
        @topic = @message_topics.success
      rescue NotImplementedError => e
        @error = e
      rescue => e
        @error = e
      end

      @timer.cancel if @timer
      @worker.terminate! rescue Celluloid::DeadActorError

      publish_notification @topic

      return unless @error && !@error.is_a?(Celluloid::Task::TerminatedError)

      @callbacks.worker_failed.call @error, @worker_class
    end

    private

    def publish_notification topic
      async.publish(topic, @sqs_id) rescue Celluloid::DeadActorError
    end
  end
end
