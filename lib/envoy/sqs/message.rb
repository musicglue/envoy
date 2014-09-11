module Envoy
  module SQS
    class Message
      class InvalidMessageFormatError < StandardError; end

      INACTIVITY_TIMEOUT = 10
      include Celluloid
      include Celluloid::Notifications
      include Envoy::Logging

      finalizer :finalize

      attr_reader :sqs_id, :receipt, :queue_name, :notification_topic,
                  :header, :body, :id, :type

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
        log_data

        @notifer = subscribe(@notification_topic, :handle_notification)

        fail InvalidMessageFormatError unless @header && @body
      rescue => e
        error log_data.merge(at: 'initialize'), e

        @header ||= { type: 'message' }.with_indifferent_access
        @body ||= {}
        @sqs_message_body = { header: @header, body: @body }.with_indifferent_access

        unprocessable

        return nil
      end

      def complete
        debug log_data.merge(at: 'complete')
        @sqs.delete_message(@receipt)
        terminate
      end

      def died
        info log_data.merge(at: 'died', 'retry' => true)
        Envoy.config.messages.died.call(self)
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

      def unprocessable
        info log_data.merge(at: 'unprocessable', 'retry' => false)
        Envoy.config.messages.unprocessable.call(self)
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
        @sqs_message_body
      end

      def heartbeat
        @sqs.extend_invisibility(@receipt, (INACTIVITY_TIMEOUT * 2))
        @timer.reset
      end
    end
  end
end
