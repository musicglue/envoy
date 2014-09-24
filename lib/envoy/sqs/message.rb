module Envoy
  module SQS
    class Message
      class InvalidMessageFormatError < StandardError; end
      class UnprocessableMessageError < StandardError; end
      class DeadMessageError < StandardError; end

      INACTIVITY_TIMEOUT = 10
      include Celluloid
      include Celluloid::Notifications
      include Envoy::Logging

      finalizer :finalize

      attr_reader :sqs_id, :receipt, :queue_name, :notification_topic,
                  :header, :body, :id, :type,
                  :raw_message

      alias_method :headers, :header

      def initialize(packet, queue, fetcher_id)
        @raw_message = packet[:body]
        @fetcher_id = fetcher_id
        @sqs = queue
        @queue_name = queue.queue_name
        @timer = after(INACTIVITY_TIMEOUT) { died }
        @received_at = Time.now
        @receipt = packet[:receipt_handle].strip
        @sqs_id = packet[:message_id].strip
        @notification_topic = "message_#{@sqs_id}"

        @parsed_message = JSON.parse(raw_message).with_indifferent_access

        @header = @parsed_message['headers'] || @parsed_message['header']
        @body = @parsed_message['body']

        @id = @header[:id]
        @type = @header[:type].underscore.to_sym
        log_data

        @notifer = subscribe(@notification_topic, :handle_notification)

        fail InvalidMessageFormatError unless @header && @body
      rescue => e
        @header ||= { type: 'message' }.with_indifferent_access
        @body ||= {}
        @parsed_message = { header: @header, body: @body }.with_indifferent_access

        unprocessable e

        return nil
      end

      def complete
        debug log_data.merge(at: 'complete')
        @sqs.delete_message(@receipt)
        terminate
      end

      def died
        error = DeadMessageError.new
        error.set_backtrace caller

        callback = Envoy.config.callbacks.message_died
        callback.call(self, error) if callback

        terminate
      end

      def finalize
        @timer.cancel
        publish_to_fetcher @sqs_id
      end

      def handle_notification(_, payload)
        method = payload.to_sym
        return unless respond_to? method
        send method
      end

      def log_data
        @log_data ||= {
          component: 'message',
          message_id: @id,
          message_type: @type,
          sqs_id: @sqs_id,
          fetcher_id: @fetcher_id
        }
      end

      def unprocessable error = nil
        error ||= UnprocessableMessageError.new.tap do |e|
          e.set_backtrace caller
        end

        error log_data.merge(at: 'unprocessable', 'retry' => false), error

        callback = Envoy.config.callbacks.message_unprocessable
        callback.call(self, error) if callback

        @sqs.delete_message(@receipt)
        terminate if Thread.current[:celluloid_actor].mailbox.alive?
      end

      def publish_to_fetcher *args
        notifier = Celluloid::Notifications.notifier
        notifier.async.publish "free_#{@fetcher_id}", *args
      rescue Celluloid::DeadActorError => e
        warn log_data.merge(at: 'publish_to_fetcher', args: args.inspect), e
      end

      def to_h
        @parsed_message
      end

      def heartbeat
        @sqs.extend_invisibility(@receipt, (INACTIVITY_TIMEOUT * 2))
        @timer.reset
      end
    end
  end
end
