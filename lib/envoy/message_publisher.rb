module Envoy
  class MessagePublisher
    def initialize
      config = Envoy.config
      config.validate!

      @sns = Envoy::Sns.client config
      @arns = Envoy::Arns.new config
      @sanitizer = MessageSanitizer.new
    end

    def publish message
      message = message.to_h if message.is_a?(Envoy::Message)
      message = @sanitizer.sanitize message

      message_type = message['header']['type'].underscore
      topic = EnvironmentalName.new(message_type).to_s
      topic_arn = @arns.sns_topic_arn topic

      @sns.publish topic_arn: topic_arn, message: message.to_json
    end
  end
end
