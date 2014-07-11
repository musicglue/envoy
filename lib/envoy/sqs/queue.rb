module Envoy
  module SQS
    class Queue
      include Celluloid::Logger

      attr_reader :queue_name

      def initialize(queue_name, options = {})
        @options      = options.reverse_merge credentials: Envoy.credentials, region: Envoy.config.aws.region
        @queue_name   = [queue_name.to_s.dasherize, Envoy.env].join('-')
        @mutex        = Mutex.new
      end

      def connection
        return @connection if @connection

        @connection = Aws.sqs @options
        create_queue if missing_queue?
        @connection
      end

      def refresh
        @queues = nil
        @arn = nil
        @inbound_queue = nil
      end

      def create_queue
        connection.create_queue(queue_name: @queue_name)
      end

      def arn
        @arn ||= begin
          response = connection.get_queue_attributes(queue_url: inbound_queue, attribute_names: ['QueueArn'])
          response.attributes['QueueArn'].strip
        end
      end

      def cmb?
        arn.split(':', 3)[1] == 'cmb'
      end

      def inbound_queue
        @inbound_queue ||= begin
          connection.get_queue_url(queue_name: @queue_name).data.queue_url
        rescue Aws::SQS::Errors::NonExistentQueue
          nil
        end
      end

      def attributes=(value = {})
        connection.set_queue_attributes(queue_url: inbound_queue, attributes: value)
      end

      def missing_queue?
        inbound_queue.blank?
      end

      def extend_invisibility(message_handle, timeout)
        connection.change_message_visibility(queue_url: inbound_queue,
                                             receipt_handle: message_handle,
                                             visibility_timeout: timeout)
      end

      def delete_message(message_handle)
        connection.delete_message(queue_url: inbound_queue, receipt_handle: message_handle)
      end

      def pop(number = 10)
        @mutex.synchronize do
          response = connection.receive_message(queue_url: inbound_queue, max_number_of_messages: number)
          return if response.data.nil?
          response.messages.map do |message|
            message
          end
        end
      end
    end
  end
end
