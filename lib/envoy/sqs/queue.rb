module Envoy
  module SQS
    class Queue
      include Celluloid::Logger

      attr_reader :queue_name
      def initialize(queue_name, options={})
        options.reverse_merge! credentials: Envoy.credentials, region: Envoy.config.aws.region
        @queue_name   = [queue_name.to_s.dasherize, Envoy.env].join('-')
        @connection   = Aws.sqs(options)
        @mutex        = Mutex.new
      end

      def connection
        if @connected
          @connection
        else
          create_queue if missing_queue?
          @connected = true
          @connection
        end
      end

      def refresh
        @queues = nil
        @arn = nil
        @inbound_queue = nil
      end

      def queue_list
        @queues ||= connection.list_queues.queue_urls.map(&:strip)
      end

      def create_queue
        connection.create_queue(queue_name: @queue_name)
      end

      def arn
        @arn ||= connection.get_queue_attributes(queue_url: inbound_queue, attribute_names: ['QueueArn']).attributes['QueueArn'].strip
      end

      def cmb?
        arn.split(':', 3)[1] == 'cmb'
      end

      def inbound_queue
        @inbound_queue ||= queue_list.find { |x| x =~ /#{@queue_name}/ }
      end

      def set_attribute(value={})
        connection.set_queue_attributes(queue_url: inbound_queue, attributes: value )
      end

      def missing_queue?
        inbound_queue.blank?
      end

      def extend_invisibility(message_handle, timeout)
        connection.change_message_visibility(queue_url: inbound_queue, receipt_handle: message_handle, visibility_timeout: timeout)
      end

      def delete_message(message_handle)
        connection.delete_message(queue_url: inbound_queue, receipt_handle: message_handle)
      end

      def pop(number)
        @mutex.synchronize do
          messages = connection.receive_message(queue_url: inbound_queue, max_number_of_messages: number).messages || []
          messages.map do |message|
            message
          end
        end
      end

    end
  end
end
