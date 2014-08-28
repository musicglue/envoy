module Envoy
  module SQS
    class Message
      class InvalidMessageFormatError < StandardError; end

      INACTIVITY_TIMEOUT = 10
      include Celluloid
      include Celluloid::Logger
      include Celluloid::Notifications

      finalizer :finalize

      attr_reader :sqs_id, :receipt, :header, :body
      alias_method :headers, :header

      def initialize(packet, queue, fetcher_id)
        @fetcher_id   = fetcher_id
        @sqs          = queue
        @timer        = after(INACTIVITY_TIMEOUT) { died }
        @received_at  = Time.now
        @receipt      = packet[:receipt_handle].strip
        @sqs_id       = packet[:message_id].strip

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
        "message_#{sqs_id}"
      end

      def id
        @id ||= header[:id]
      end

      def type
        @type ||= header[:type].underscore.to_sym
      end

      def heartbeat
        @sqs.extend_invisibility(@receipt, (INACTIVITY_TIMEOUT * 2))
        @timer.reset
      end

      def complete
        debug "at=message_completed #{log_data}"
        @sqs.delete_message(@receipt)
        terminate
      end

      def died
        info "at=message_died retry=true #{log_data}"
        Envoy.config.messages.died.call(self)
        terminate
      end

      def unprocessable
        info "at=message_unprocessable retry=false #{log_data}"
        Envoy.config.messages.unprocessable.call(self)
        @sqs.delete_message(@receipt)
        terminate
      end

      def finalize
        Celluloid::Notifications.notifier.async.publish("free_#{@fetcher_id}", @sqs_id)
        @timer.cancel
      end

      def handle_notification(_topic, payload)
        send(payload.to_sym) if respond_to? payload.to_sym
      end

      def log_data
        "message_id=#{id} message_type=#{type} "\
        "sqs_id=#{sqs_id}"
      end
    end
  end
end
