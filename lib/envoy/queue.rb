module Envoy
  class Queue
    InvalidMessageDequeuedError = Class.new StandardError

    include Celluloid
    include Celluloid::Notifications
    include Envoy::Logging

    def initialize name, sqs, config
      @name = name
      @sqs = sqs
      @config = config
      @queue_config = config.get_queue name

      @message_topics = Watchdog::MessageTopics.new(
        "message_processed_on_#{@name}",
        "message_failed_on_#{@name}",
        "message_heartbeat_on_#{@name}")

      @stopped = true
      @register = Register.new @queue_config.message_concurrency
      @router = Router.new @queue_config
      @log_data = { component: 'queue', name: @name }

      subscribe @message_topics.success, :acknowledge_message
      subscribe @message_topics.failure, :unacknowledge_message
      subscribe @message_topics.heartbeat, :message_heartbeat
    end

    attr_reader :message_topics

    def acknowledge_message _topic, sqs_id
      info @log_data.merge(
        at: 'acknowledge_message',
        sqs_id: sqs_id)

      handle_completed_message(sqs_id) do |message|
        @sqs.delete_message @name, message.receipt_handle
      end
    end

    def message_heartbeat _topic, sqs_id
      info @log_data.merge(
        at: 'message_heartbeat',
        sqs_id: sqs_id)

      @sqs.extend_message_invisibility(
        @name,
        @register[sqs_id].message.receipt_handle,
        @queue_config.visibility_timeout)
    end

    def start
      return unless @stopped
      @stopped = false

      info @log_data.merge(at: 'start', name: @name)

      loop do
        break unless current_actor.alive?
        break if @stopped

        dequeue_messages
        sleep sleep_time
      end

      info @log_data.merge(at: 'exiting', name: @name)
    end

    def stop
      info @log_data.merge(at: 'stop', name: @name)
      @stopped = true
    end

    def unacknowledge_message _topic, sqs_id
      warn @log_data.merge(
        at: 'unacknowledge_message',
        sqs_id: sqs_id)

      handle_completed_message sqs_id
    end

    private

    def dequeue_messages
      return if @register.free == 0

      messages = @sqs.receive_messages @name, @register.free
      @messages_dequeued = messages.valid.count

      messages.valid.each do |message|
        next unless (worker_class = @router.route(message))

        debug @log_data.merge(
          at: 'routing',
          sqs_id: message.sqs_id,
          worker: worker_class.to_s.underscore)

        watchdog = Watchdog.new(
          sqs_id: message.sqs_id,
          message_topics: @message_topics,
          worker: worker_class.new(message),
          callbacks_config: @config.callbacks,
          queue_config: @queue_config)

        @register.add message, watchdog

        watchdog.async.process
      end

      messages.invalid.each do |message|
        error @log_data.merge(
          at: 'invalid_message_dequeued',
          message: message)

        @config.callbacks.invalid_message_dequeued.call InvalidMessageDequeuedError.new, message
      end

      debug @log_data.merge(
        at: 'dequeue_messages',
        messages_dequeued: @messages_dequeued
      ) if @messages_dequeued > 0
    end

    def sleep_time
      (@messages_dequeued == 0) || (@register.free == 0) ? 1 : 0.1
    end

    def handle_completed_message sqs_id
      entry = @register.remove sqs_id
      yield entry.message if block_given?
      sleep 0.1
      entry.watchdog.terminate! rescue Celluloid::DeadActorError
    end
  end
end
