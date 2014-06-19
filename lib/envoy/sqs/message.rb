module Envoy
  module SQS
    class Message
    class InvalidMessageFormatError < StandardError; end
      INACTIVITY_TIMEOUT = 10
      include Celluloid
      include Celluloid::Logger
      include Celluloid::Notifications

      finalizer :finalize

      attr_reader :id, :receipt

      def initialize(packet, queue = AssetRefinery.queue, fetcher_id)
        @fetcher_id = fetcher_id
        @sqs = queue
        @timer = after(INACTIVITY_TIMEOUT) { died }
        @received_at = Time.now
        @receipt = packet['ReceiptHandle'].strip
        @id = packet['MessageId'].strip

        message_body = JSON.parse(packet['Body'])
        @header = message_body['header']
        @body = message_body['body']
        @notifer = subscribe(notification_topic, :handle_notification)
        fail InvalidMessageFormatError unless @header && @body
      rescue => e
        error e.inspect
        @header ||= { type: 'message' }
        @body   ||= {}
        unprocessable
        return nil
      end

      def header
        @header.with_indifferent_access if @header
      end

      def body
        @body.with_indifferent_access if @body
      end

      def notification_topic
        "message_#{id}"
      end

      def type
        header[:type].to_sym
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
        info 'Message has errored and will be retried'
        message_header = @header.merge(type: "#{type}_failed")
        terminate
      end

      def unprocessable
        info 'Mark message as unprocessable and remove from queue'
        message_header = @header.merge(type: "#{type}_unprocessable")
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
