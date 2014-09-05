require 'securerandom'
module Envoy
  class Fetcher
    include Celluloid
    include Celluloid::Logger
    include Celluloid::Notifications

    attr_reader :currently_processing

    def initialize(concurrency, broker, queue)
      @currently_processing = Set.new
      @maximum_concurrently = concurrency
      @broker = broker
      @run = true
      @fetcher_id = SecureRandom.hex(4)
      @queue = queue
      @queue_name = queue.queue_name
      @log_data = log_data

      link @broker
      subscribe "free_#{@fetcher_id}", :free_slot
    end

    def run
      while @run
        fetch
        sleep(@last_fetch_was_empty ? 1 : 0.1)
      end
    end

    def stop
      @run = false
      info "at=fetcher_stop #{@log_data}"
      terminate
    end

    def fetch
      debug "at=fetch free_slots=#{available_slots} #{@log_data}"
      fetch_messages if available_slots?
    rescue => e
      Celluloid::Logger.with_backtrace(e.backtrace) do |logger|
        logger.error %(at=fetcher_error error="#{Envoy::Logging.escape(e.to_s)}" #{@log_data})
      end
    end

    def process(message)
      message = Envoy::SQS::Message.new(message, @queue, @fetcher_id)

      return unless message.alive?

      @currently_processing << message.sqs_id
      @broker.process_message(message, @queue)
    end

    def fetch_messages
      @last_fetch_was_empty = true

      @queue.pop(available_slots).each do |message|
        @last_fetch_was_empty = false
        process(message)
      end
    end

    def free_slot(_topic, uuid)
      @currently_processing.delete(uuid)
    end

    private

    def available_slots
      @maximum_concurrently - @currently_processing.size
    end

    def available_slots?
      available_slots > 0
    end

    def log_data
      "fetcher_id=#{@fetcher_id} queue=#{@queue_name}"
    end
  end
end
