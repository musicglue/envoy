module Envoy
  module Worker
    extend ActiveSupport::Concern

    included do
      include Celluloid
      include Celluloid::Logger
      include Celluloid::Notifications

      attr_reader :message, :topic, :timer
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
        process
      end
    end

    def process
      #noop
      raise NotImplemetedError
    end

    def safely
      return unless block_given?
      begin
        yield
        complete
      rescue => e
        error e.inspect
        failed
      ensure
        terminate
      end
    end

  end
end
