module Envoy
  module Worker
    extend ActiveSupport::Concern

    included do
      include Celluloid
      include Celluloid::Logger
      include Celluloid::Notifications

      attr_reader :message, :topic, :timer
    end

    module ClassMethods
      def middleware
        @middleware ||= []
      end
    end

    def initialize(message)
      @message = message
      @topic = @message.notification_topic
      @timer = every(5) { publish(@topic, :heartbeat) }
    end

    def complete
      @timer.cancel
      publish(@topic, :complete)
    end

    def failed
      @timer.cancel
      publish(@topic, :died)
    end

    def safely_process
      safely do
        stack = ::Middleware::Builder.new
        (self.class.middleware + [Envoy::Middlewares::Worker]).each { |m| stack.use m, self }
        stack.call
      end
    end

    def process
      # noop
      fail NotImplemetedError
    end

    def safely
      return unless block_given?

      info "at=worker_start #{log_data}"

      begin
        start_time = Time.now
        yield
        end_time = Time.now

        complete

        info "at=worker_end duration=#{(end_time - start_time).round}s #{log_data}"
      rescue => e
        failed

        Celluloid::Logger.with_backtrace(e.backtrace) do |logger|
          logger.error "at=worker_error error=#{e} #{log_data}"
        end
      ensure
        terminate
      end
    end

    def log_data
      "worker=#{self.class.name} queue=#{@message.queue_name} "\
      "message_id=#{@message.id} message_type=#{@message_type} "\
      "sqs_id=#{@message.sqs_id}"
    end
  end
end
