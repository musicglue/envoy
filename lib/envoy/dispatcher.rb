module Envoy
  class Dispatcher
    include Celluloid
    include Celluloid::Notifications
    include Envoy::Logging

    trap_exit :actor_died

    def process(worker_klass, message)
      @worker_klass = worker_klass
      @sqs_id = message.sqs_id

      # this is not the 'application' topic of the message, e.g. order_received.
      # it is the topic used to broadcast notification about this message's
      # lifecycle over celluloid's internal pub/sub mechanism.
      @notification_topic = message.notification_topic

      @timer = every(5) do
        info log_data.merge(at: 'heartbeat')
        publish @notification_topic, :heartbeat
      end

      @worker_running = true

      worker = worker_klass.new(message, self)
      link worker

      begin
        worker.async.safely_process

        loop do
          sleep 1
          break unless @worker_running
        end
      ensure
        unlink worker
        # rubocop:disable Style/RescueModifier
        worker.terminate rescue Celluloid::DeadActorError
        # rubocop:enable Style/RescueModifier
      end
    end

    def worker_completed
      @timer.cancel
      publish @notification_topic, :complete
      @worker_running = false
    end

    def worker_failed
      @timer.cancel
      publish @notification_topic, :died
      @worker_running = false
    end

    def actor_died actor, reason
      warn log_data.merge(at: 'actor_died', reason: reason)
      @timer.cancel if @timer
      @worker_running = false
    end

    def log_data
      { component: 'dispatcher', worker_klass: @worker_klass, sqs_id: @sqs_id }
    end
  end
end
