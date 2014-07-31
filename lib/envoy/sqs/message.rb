module Envoy
  module SQS
    class Message
      class InvalidMessageFormatError < StandardError; end

      INACTIVITY_TIMEOUT = 10
      include Celluloid
      include Celluloid::Logger
      include Celluloid::Notifications

      finalizer :finalize

      attr_reader :id, :receipt, :header, :body
      alias_method :headers, :header

      def initialize(packet, queue, fetcher_id)
        @fetcher_id   = fetcher_id
        @sqs          = queue
        @timer        = after(INACTIVITY_TIMEOUT) { died }
        @received_at  = Time.now
        @receipt      = packet[:receipt_handle].strip
        @id           = packet[:message_id].strip

        message_body = JSON.parse(packet[:body])

        @header   = message_body['header'].with_indifferent_access
        @body     = message_body['body'].with_indifferent_access
        @notifer  = subscribe(notification_topic, :handle_notification)

        fail InvalidMessageFormatError unless @header && @body
      rescue => e
        error e.inspect
        @header ||= { type: 'message' }.with_indifferent_access
        @body   ||= {}
        unprocessable
        return nil
      end

      def queue_name
        @sqs.queue_name
      end

      def notification_topic
        "message_#{id}"
      end

      def type
        @type ||= header[:type].underscore.to_sym
      end

      def heartbeat
        @sqs.extend_invisibility(@receipt, (INACTIVITY_TIMEOUT * 2))
        @timer.reset
      end

      def complete
        @sqs.delete_message(@receipt)
        terminate
      end

      def died
        Envoy.config.messages.died.call(self)
        info 'Message has errored and will be retried'
        terminate
      end

      def unprocessable
        Envoy.config.messages.unprocessable.call(self)
        info 'Mark message as unprocessable and remove from queue'
        @sqs.delete_message(@receipt)
        terminate
      end

      def finalize
        Celluloid::Notifications.notifier.async.publish("free_#{@fetcher_id}", @id)
        @timer.cancel
      end

      def handle_notification(_topic, payload)
        send(payload.to_sym) if respond_to? payload.to_sym
      end
    end
  end
end
