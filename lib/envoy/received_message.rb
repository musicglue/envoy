module Envoy
  class ReceivedMessage
    InvalidMessagePayloadError = Class.new StandardError

    def initialize sqs_id, receipt_handle, queue, payload
      @sqs_id = sqs_id
      @receipt_handle = receipt_handle
      @queue = queue
      @payload = payload

      @headers = @payload[:headers] || @payload[:header]
      @body = @payload[:body]

      unless @headers.key?(:id) && @headers.key?(:type) && @body.is_a?(Hash)
        fail InvalidMessagePayloadError
      end
    end

    attr_reader :sqs_id, :receipt_handle, :queue, :headers, :body

    def id
      @headers[:id]
    end

    def type
      @headers[:type]
    end

    def to_h
      @payload
    end
  end
end
