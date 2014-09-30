module Envoy
  module SQS
    class Queue
      include Envoy::Logging

      attr_reader :queue_name, :sqs, :config

      def initialize config, endpoint
        @config = config
        @endpoint = endpoint
        @mutex = Mutex.new
        @queue_name = EnvironmentalName.new(config.name).to_s

        attrs = {}
        attrs[:endpoint] = endpoint unless endpoint.blank?

        @sqs = Aws::SQS::Client.new attrs
      end

      def arn
        @arn ||= begin
          response = @sqs.get_queue_attributes(
            queue_url: inbound_queue,
            attribute_names: ['QueueArn'])

          response.attributes['QueueArn'].strip
        end
      end

      def attributes=(attrs = {})
        @sqs.set_queue_attributes(
          queue_url: inbound_queue,
          attributes: attrs)
      end

      def delete_message(message_handle)
        debug log_data.merge(
          at: 'delete_message',
          handle: message_handle)

        @sqs.delete_message(
          queue_url: inbound_queue,
          receipt_handle: message_handle)
      end

      def extend_invisibility(message_handle, timeout)
        debug log_data.merge(
          at: 'extend_invisibility',
          handle: message_handle,
          extension: timeout)

        @sqs.change_message_visibility(
          queue_url: inbound_queue,
          receipt_handle: message_handle,
          visibility_timeout: timeout)
      end

      def inbound_queue
        @inbound_queue ||= begin
          @sqs.get_queue_url(queue_name: @queue_name).data.queue_url
        rescue Aws::SQS::Errors::NonExistentQueue
          warn log_data.merge(
            at: 'inbound_queue',
            error: 'non_existant_queue')
          nil
        end
      end

      def log_data
        @log_data ||= { component: 'queue', name: @queue_name }
      end

      def pop(number = 10)
        @mutex.synchronize do
          response = @sqs.receive_message(
            queue_url: inbound_queue,
            max_number_of_messages: number)

          response.messages || []
        end
      end

      def refresh
        @queues = nil
        @arn = nil
        @inbound_queue = nil
      end
    end
  end
end
