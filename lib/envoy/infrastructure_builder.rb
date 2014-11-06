# rubocop:disable Metrics/ClassLength
module Envoy
  class InfrastructureBuilder
    include Envoy::Logging

    def initialize config
      @config = config
      @config.validate!
      @arns = Envoy::Arns.new @config
      @log_data ||= { component: 'infrastructure_builder' }
    end

    def build_policies
      puts "Application policy for the #{Rails.env} environment:"
      puts ''
      puts application_policy
      puts ''
      puts "Add this into your application's IAM group."
    end

    def build_queues
      log_data = @log_data.merge at: 'build_queues'

      if @config.dead_letter_queue
        create_queue log_data, @config.dead_letter_queue, [], all_topics
      end

      @config.queues.each do |queue|
        topics = queue.subscribed_topics
        create_queue log_data, queue, topics, topics
      end
    end

    def build_topics
      sns = Envoy::Sns.client @config
      log_data = @log_data.merge at: 'build_topics', endpoint: sns.config[:endpoint].to_s

      all_topics.each do |topic|
        info log_data.merge topic: topic
        sns.create_topic name: topic
      end
    end

    private

    def all_queues
      names = @config.queues.map(&:name)
      names += [@config.dead_letter_queue.name] if @config.dead_letter_queue

      names.flatten.uniq.map do |queue|
        EnvironmentalName.new(queue).to_s
      end
    end

    def all_topics
      @config.queues.map(&:subscribed_topics).flatten.uniq
    end

    def arn_array_policy_string arns, indent
      arns.sort.map { |arn| %(#{indent}"#{arn}") }.join(",\n")
    end

    def application_policy
      topic_arns = all_topics.map { |topic| @arns.sns_topic_arn topic }
      queue_arns = all_queues.map { |queue| @arns.sqs_queue_arn queue }

      <<-EOS.strip_heredoc
      {
        "Version": "2012-10-17",
        "Statement": [
          {
            "Effect": "Allow",
            "Action": [
              "sns:CreateTopic",
              "sns:Publish",
              "sns:SetEndpointAttributes",
              "sns:Subscribe"
            ],
            "Resource": [
#{arn_array_policy_string topic_arns, '              '}
            ]
          },
          {
            "Effect": "Allow",
            "Action": [
              "sns:SetSubscriptionAttributes"
            ],
            "Resource": [
              "#{@arns.sns_topic_arn '*'}"
            ]
          },
          {
            "Effect": "Allow",
            "Action": [
              "sqs:ChangeMessageVisibility",
              "sqs:CreateQueue",
              "sqs:DeleteMessage",
              "sqs:GetQueueAttributes",
              "sqs:GetQueueUrl",
              "sqs:ReceiveMessage",
              "sqs:SetQueueAttributes"
            ],
            "Resource": [
#{arn_array_policy_string queue_arns, '              '}
            ]
          }
        ]
      }
      EOS
    end

    def create_queue log_data, queue, subscribed_topics, permitted_topics
      sqs = Envoy::Sqs.client @config
      sns = Envoy::Sns.client @config

      sqs_endpoint = sqs.config[:endpoint].to_s
      sns_endpoint = sns.config[:endpoint].to_s

      log_data = log_data.merge sqs_endpoint: sqs_endpoint, sns_endpoint: sns_endpoint

      queue_name = EnvironmentalName.new(queue.name).to_s

      info log_data.merge step: 'create_queue', name: queue_name
      sqs.create_queue queue_name: queue_name
      queue_url = wait_for_queue sqs, queue_name
      queue_arn = sqs.get_queue_attributes(
        queue_url: queue_url,
        attribute_names: ['QueueArn']).attributes['QueueArn']

      attributes = {
        'DelaySeconds' => queue.delay_seconds.to_s,
        'MessageRetentionPeriod' => queue.message_retention_period.to_s,
        'VisibilityTimeout' => queue.visibility_timeout.to_s
      }

      if sqs_endpoint =~ /amazonaws.com/
        if queue.respond_to?(:redrive_policy)
          policy = if queue.redrive_policy.enabled
                     redrive_policy queue.redrive_policy.dead_letter_queue, queue.redrive_policy.max_receive_count
                   else
                     '{}'
                   end

          attributes.merge! 'RedrivePolicy' => policy
        end

        policy = queue_policy queue_name, permitted_topics
        attributes.merge! 'Policy' => policy
      end

      info log_data.merge step: 'set_queue_attributes', name: queue_name, attributes: attributes
      sqs.set_queue_attributes queue_url: queue_url, attributes: attributes

      subscribed_topics.each do |topic|
        topic_arn = @arns.sns_topic_arn topic
        subscription_log_data = log_data.merge queue_arn: queue_arn, topic_arn: topic_arn

        if @config.sns.protocol == 'cqs'
          info subscription_log_data.merge step: 'adding_subscribe_permission'
          sns.add_permission topic_arn: topic_arn,
                             label: "subscribe-#{@config.aws.account_id}-#{Time.now.strftime('%Y%m%d%H%M%S')}",
                             aws_account_id: [@config.aws.account_id],
                             action_name: ['Subscribe']
        end

        info subscription_log_data.merge step: 'subscribing_queue_to_topic', protocol: @config.sns.protocol
        subscription_arn = sns.subscribe(
          endpoint: queue_arn,
          protocol: @config.sns.protocol,
          topic_arn: topic_arn).subscription_arn

        attribute = 'RawMessageDelivery'
        value = queue.subscriptions.raw_message_delivery.to_s

        info subscription_log_data.merge(
          step: 'setting_subscription_attributes',
          attribute: attribute,
          value: value)

        sns.set_subscription_attributes(
          subscription_arn: subscription_arn,
          attribute_name: attribute,
          attribute_value: value)
      end
    end

    def queue_policy queue, topics
      queue_arn = @arns.sqs_queue_arn queue
      topic_arns = topics.map { |topic| @arns.sns_topic_arn topic }

      <<-EOS.strip_heredoc
      {
        "Version": "2008-10-17",
        "Id": "#{queue_arn}/envoy-generated-policy",
        "Statement": [
          {
            "Effect": "Allow",
            "Principal": {
              "AWS": "*"
            },
            "Action": "SQS:SendMessage",
            "Resource": "#{queue_arn}",
            "Condition": {
              "ArnEquals": {
                "aws:SourceArn": [
#{arn_array_policy_string topic_arns, '                  '}
                ]
              }
            }
          }
        ]
      }
      EOS
    end

    def redrive_policy dead_letter_queue, max_receive_count
      arn = @arns.sqs_queue_arn EnvironmentalName.new(dead_letter_queue).to_s
      %({"maxReceiveCount":"#{max_receive_count}", "deadLetterTargetArn":"#{arn}"})
    end

    def wait_for_queue sqs, name
      url = ''

      loop do
        begin
          url = sqs.get_queue_url(queue_name: name).data.queue_url
        rescue Aws::SQS::Errors::NonExistentQueue
          sleep 1
        end

        break unless url.blank?
      end

      url
    end
  end
end
# rubocop:enable Metrics/ClassLength
