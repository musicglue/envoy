module Envoy
  class Arns
    def initialize config
      @config = config
    end

    def sns_arn
      if @config.sns.protocol == 'cqs'
        "arn:cmb:cns:ccp:#{@config.aws.account_id}"
      else
        "arn:aws:sns:#{@config.aws.region}:#{@config.aws.account_id}"
      end
    end

    def sns_topic_arn topic
      "#{sns_arn}:#{topic}"
    end

    def sqs_arn
      if @config.sqs.protocol == 'cqs'
        "arn:cmb:cqs:ccp:#{@config.aws.account_id}"
      else
        "arn:aws:sqs:#{@config.aws.region}:#{@config.aws.account_id}"
      end
    end

    def sqs_queue_arn queue
      "#{sqs_arn}:#{queue}"
    end
  end
end
