module Envoy
  module SQS
    class Message
      class InvalidMessageFormatError < StandardError; end

      INACTIVITY_TIMEOUT = 10
      include Celluloid
      include Celluloid::Logger
      include Celluloid::Notifications

      finalizer :finalize

      attr_reader :sqs_id, :receipt, :queue_name, :notification_topic,
                  :header, :body, :id, :type, :log_data

      alias_method :headers, :header

      def initialize(packet, queue, fetcher_id)
        @fetcher_id = fetcher_id
        @sqs = queue
        @queue_name = queue.queue_name
        @timer = after(INACTIVITY_TIMEOUT) { died }
        @received_at = Time.now
        @receipt = packet[:receipt_handle].strip
        @sqs_id = packet[:message_id].strip
        @notification_topic = "message_#{@sqs_id}"

        @sqs_message_body = JSON.parse(packet[:body]).with_indifferent_access

        @header = @sqs_message_body['header']
        @body = @sqs_message_body['body']

        @id = @header[:id]
        @type = @header[:type].underscore.to_sym
        @log_data = "message_id=#{@id} message_type=#{@type} sqs_id=#{@sqs_id}"

        @notifer = subscribe(@notification_topic, :handle_notification)

        fail InvalidMessageFormatError unless @header && @body
      rescue => e
        Celluloid::Logger.with_backtrace(e.backtrace) do |logger|
          logger.error %(at=message_initialization error="#{Envoy::Logging.escape(e.to_s)}" #{@log_data})
        end

        @header ||= { type: 'message' }.with_indifferent_access
        @body ||= {}
        @sqs_message_body = { header: @header, body: @body }.with_indifferent_access

        unprocessable

        return nil
      end

      def to_h
        @sqs_message_body
      end

      def heartbeat
        @sqs.extend_invisibility(@receipt, (INACTIVITY_TIMEOUT * 2))
        @timer.reset
      end

      def complete
        debug "at=message_completed #{@log_data}"
        @sqs.delete_message(@receipt)
        terminate
      end

      def died
        info "at=message_died retry=true #{@log_data}"
        Envoy.config.messages.died.call(self)
        terminate
      end

      def unprocessable
        info "at=message_unprocessable retry=false #{@log_data}"
        Envoy.config.messages.unprocessable.call(self)
        @sqs.delete_message(@receipt)
        terminate if Thread.current[:celluloid_actor].mailbox.alive?
      end

      def finalize
        Celluloid::Notifications.notifier.async.publish("free_#{@fetcher_id}", @sqs_id)
        @timer.cancel
      end

      def handle_notification(_topic, payload)
        send(payload.to_sym) if respond_to? payload.to_sym
      end
    end
  end
end
