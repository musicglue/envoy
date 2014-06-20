module Envoy
  module SQS
    class Queue
      include Celluloid::Logger

      attr_reader :connection, :queue_name
      def initialize(queue_name, options={})
        @queue_name   = queue_name
        @connection   = Aws.sqs(options.merge(queue_name: queue_name))
        @mutext       = Mutex.new
        create_queue if missing_queue?
      end

      def refresh
        @queues = nil
        @arn = nil
        @inbound_queue = nil
      end

      def queue_list
        @queues ||= connection.list_queues.data[:body]['QueueUrls'].map(&:strip)
      end

      def create_queue
        connection.create_queue(@queue_name)
      end

      def arn
        @arn ||= connection.get_queue_attributes(inbound_queue, 'QueueArn').data[:body]['Attributes']['QueueArn'].strip
      end

      def cmb?
        arn.split(':', 3)[1] == 'cmb'
      end

      def inbound_queue
        @inbound_queue ||= queue_list.find { |x| x =~ /#{@queue_name}/ }
      end

      def set_attribute attribte, value
        connection.set_queue_attributes(inbound_queue, attribte, (value.is_a?(Hash) ? value.to_json : value))
      end

      def missing_queue?
        inbound_queue.blank?
      end

      def extend_invisibility(message_handle, timeout)
        connection.change_message_visibility(inbound_queue, message_handle, timeout)
      end

      def delete_message(message_handle)
        connection.delete_message(inbound_queue, message_handle)
      end

      def pop(number)
        @mutex.synchronize do
          connection.receive_message(inbound_queue, 'MaxNumberOfMessages' => number)[:body]['Message'].map do |message|
            message
          end
        end
      end

    end
  end
end
