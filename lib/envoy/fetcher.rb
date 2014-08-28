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
      @broker               = broker
      @run                  = true
      @fetcher_id           = SecureRandom.hex(4)
      @queue                = queue

      link @broker
      subscribe "free_#{@fetcher_id}", :free_slot
    end

    def run
      while @run
        fetch
        sleep 1
      end
    end

    def stop
      @run = false
      info "at=fetcher_stop #{log_data}"
      terminate
    end

    def fetch
      debug "at=fetch free_slots=#{available_slots} #{log_data}"
      fetch_messages if available_slots?
    rescue => e
      Celluloid::Logger.with_backtrace(e.backtrace) do |logger|
        logger.error "at=fetcher_error error=#{e} #{log_data}"
      end
    end

    def process(message)
      message = Envoy::SQS::Message.new(message, @queue, @fetcher_id)

      return unless message.alive?

      @currently_processing << message.sqs_id
      @broker.process_message(message, @queue)
    end

    def fetch_messages
      @queue.pop(available_slots).each { |message| process(message) }
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
      "fetcher_id=#{@fetcher_id} queue=#{@queue.queue_name}"
    end
  end
end
