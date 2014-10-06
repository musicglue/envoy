module Envoy
  class Sqs
    ReceivedMessages = Struct.new :valid, :invalid

    def initialize client
      @client = client

      @urls = Hash.new do |hash, name|
        hash[name] = get_queue_url name
      end
    end

    def delete_message queue_name, receipt_handle
      @client.delete_message(
        queue_url: @urls[queue_name],
        receipt_handle: receipt_handle)
    end

    def extend_message_invisibility(queue_name, receipt_handle, visibility_timeout)
      @client.change_message_visibility(
        queue_url: @urls[queue_name],
        receipt_handle: receipt_handle,
        visibility_timeout: visibility_timeout)
    end

    def get_queue_arn queue_name
      @client.get_queue_attributes(
        queue_url: @urls[queue_name],
        attribute_names: ['QueueArn']
      ).attributes['QueueArn'].strip
    end

    def get_queue_url queue_name
      queue_name = EnvironmentalName.new(queue_name).to_s
      @client.get_queue_url(queue_name: queue_name).data.queue_url
    rescue Aws::SQS::Errors::NonExistentQueue
      nil
    end

    def receive_messages(queue_name, maximum = 10)
      messages = ReceivedMessages.new [], []
      return messages if maximum <= 0

      raw_messages = @client.receive_message(
        queue_url: @urls[queue_name],
        max_number_of_messages: maximum
      ).messages || []

      raw_messages.each do |message|
        begin
          messages.valid << Message.new(
            message[:message_id],
            message[:receipt_handle],
            queue_name,
            JSON.parse(message[:body]).with_indifferent_access)
        rescue
          messages.invalid << message
        end
      end

      messages
    end
  end
end
