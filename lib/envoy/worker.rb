module Envoy
  module Worker
    extend ActiveSupport::Concern

    included do
      include Celluloid
      include Celluloid::Notifications
      include Envoy::Logging
      include ::NewRelic::Agent::Instrumentation::ControllerInstrumentation

      attr_reader :message, :topic, :timer

      add_transaction_tracer :safely_process, category: :task
    end

    module ClassMethods
      def middleware
        @middleware ||= []
      end
    end

    def initialize(message)
      @message = message
      @topic = @message.notification_topic
      @timer = every(5) { heartbeat }
      log_data
    end

    def complete
      @timer.cancel
      publish_to_message :complete
    end

    def failed
      @timer.cancel
      publish_to_message :died
    end

    def logger
      Envoy::Logging
    end

    def safely_process
      NewRelic::Agent.set_transaction_name("Envoy/#{self.class.name.underscore}")

      safely do
        stack = ::Middleware::Builder.new
        (self.class.middleware + [Envoy::Middlewares::Worker]).each { |m| stack.use m, self }
        stack.call
      end
    end

    def process
      fail NotImplemetedError
    end

    def safely
      return unless block_given?

      info log_data.merge(at: 'before_process')

      begin
        start_time = Time.now
        yield
        end_time = Time.now

        info log_data.merge(at: 'after_process', duration: "#{(end_time - start_time).round}s")
        complete
      rescue => e
        error log_data.merge(at: 'safely'), e
        failed
      ensure
        terminate
      end
    end

    def heartbeat
      publish_to_message :heartbeat
    end

    def log_data
      @log_data ||= {
        component: 'worker',
        worker: self.class.name,
        queue: @message.queue_name,
        message_id: @message.id,
        message_type: @message.type,
        sqs_id: @message.sqs_id,
        topic: @topic
      }
    end

    def publish_to_message *args
      publish @topic, *args
    rescue Celluloid::DeadActorError => e
      warn log_data.merge(at: 'publish_to_message', args: args.inspect), e
    end
  end
end
