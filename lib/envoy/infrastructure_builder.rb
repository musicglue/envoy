module Envoy
  class InfrastructureBuilder
    include Envoy::Logging

    def initialize config
      @config = config
      @config.update_aws
      @log_data ||= { component: 'infrastructure_builder' }
    end

    def build_policies
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

      # @manifest[:queues].each do |queue|
      #   queue_name = [queue[:name].to_s.dasherize, Docket.env.downcase].join('-')

      #   say_status :info, "Queue #{queue_name} requested", :light_blue

      #   @sqs_connection.create_queue(queue_name: queue_name)
      #   queue_url = wait_for_queue queue_name

      #   if queue[:attributes]
      #     attrs = queue[:attributes]

      #     if attrs['RedrivePolicy'] && attrs['RedrivePolicy']['deadLetterTargetArn'].is_a?(Symbol)
      #       dead_letter_name  = [attrs['RedrivePolicy']['deadLetterTargetArn'].to_s.dasherize, Docket.env.downcase].join('-')
      #       @sqs_connection.create_queue(queue_name: dead_letter_name)
      #       dead_letter_url   = wait_for_queue dead_letter_name
      #       dead_letter_arn   = @sqs_connection.get_queue_attributes(queue_url: dead_letter_url, attribute_names: ['QueueArn']).attributes['QueueArn']
      #       attrs['RedrivePolicy']['deadLetterTargetArn'] = dead_letter_arn
      #     end
      #     @sqs_connection.set_queue_attributes(queue_url: queue_url, attributes: attrs.each_with_object({}) {|(k,v),o| o[k] = v.to_s })
      #     say_status :success, "Set #{attrs.keys.join(', ')} for #{queue_name}", :green
      #   end

      #   say_status :success, "#{queue_name} created successfully", :green
      # end
    end

    def build_topics
      sns = sns_client
      log_data = @log_data.merge at: 'build_topics', endpoint: sns.config[:endpoint].to_s

      all_topics.each do |topic|
        info log_data.merge topic: topic
        sns.create_topic name: topic
      end

      # @manifest[:topics].each do |topic|
      #   arn = @sns_connection.create_topic(name: [topic[:topic].to_s.dasherize, Docket.env.downcase].join('-')).topic_arn

      #   say_status :success, "Topic #{arn} created successfully", :green

      #   (topic[:subscriptions] || []).each do |sub|
      #     if sub[:protocol] == :sqs || sub[:protocol] == :cqs
      #       url = wait_for_queue "#{sub[:endpoint].to_s.dasherize}-#{Docket.env.downcase}"
      #       endpoint = @sqs_connection.get_queue_attributes(queue_url: url, attribute_names: ['QueueArn']).attributes['QueueArn']
      #     else
      #       endpoint = sub[:endpoint]
      #     end

      #     sub_arn = @sns_connection.subscribe(topic_arn: arn, protocol: sub[:protocol], endpoint: endpoint).subscription_arn

      #     say_status :success, "Subscription #{endpoint} created successfully", :green

      #     attributes = { RawMessageDelivery: true }.merge(sub[:attributes] || {})

      #     attributes.each do |key, value|
      #       next if key.blank? || value.blank?

      #       say_status :success, "Set #{key} on #{sub_arn}", :green

      #       @sns_connection.set_subscription_attributes(subscription_arn: sub_arn, attribute_name: key.to_s, attribute_value: value.to_s)
      #     end
      #   end
      # end
    end

    private

    def all_topics
      @config.queues.map(&:subscribed_topics).flatten.uniq
    end

    def create_queue log_data, queue, subscribed_topics, permitted_topics
      sqs = sqs_client
      sns = sns_client

      sqs_endpoint = sqs.config[:endpoint].to_s
      sns_endpoint = sns.config[:endpoint].to_s

      log_data = log_data.merge sqs_endpoint: sqs_endpoint, sns_endpoint: sns_endpoint

      queue_name = EnvironmentalName.new(queue.name).to_s

      info log_data.merge step: 'create_queue', name: queue_name
      sqs.create_queue queue_name: queue_name
      queue_url = wait_for_queue sqs, queue_name
      queue_arn = sqs.get_queue_attributes(queue_url: queue_url, attribute_names: ['QueueArn']).attributes['QueueArn']

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
        topic_arn = sns_topic_arn topic
        subscription_log_data = log_data.merge queue_arn: queue_arn, topic_arn: topic_arn

        info subscription_log_data.merge step: 'subscribing_queue_to_topic', protocol: @config.sns.protocol
        subscription_arn = sns.subscribe(endpoint: queue_arn, protocol: @config.sns.protocol, topic_arn: topic_arn).subscription_arn

        attribute = 'RawMessageDelivery'
        value = queue.subscriptions.raw_message_delivery.to_s

        info subscription_log_data.merge step: 'setting_subscription_attributes', attribute: attribute, value: value
        sns.set_subscription_attributes subscription_arn: subscription_arn, attribute_name: attribute, attribute_value: value
      end
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

    def queue_policy queue, topics
      queue_arn = sqs_queue_arn queue
      topic_arns = topics.map { |topic| sns_topic_arn topic }

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
                "aws:SourceArn": #{topic_arns.to_json}
              }
            }
          }
        ]
      }
      EOS
    end

    def redrive_policy dead_letter_queue, max_receive_count
      arn = sqs_queue_arn EnvironmentalName.new(dead_letter_queue).to_s
      %Q({"maxReceiveCount":"#{max_receive_count}", "deadLetterTargetArn":"#{arn}"})
    end

    def sns_client
      attrs = {}
      attrs[:endpoint] = @config.sns.endpoint unless @config.sns.endpoint.blank?
      Aws::SNS::Client.new attrs
    end

    def sqs_client
      attrs = {}
      attrs[:endpoint] = @config.sqs.endpoint unless @config.sqs.endpoint.blank?
      Aws::SQS::Client.new attrs
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
