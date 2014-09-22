module Envoy
  class Fetcher
    include Celluloid
    include Celluloid::Notifications
    include Envoy::Logging

    attr_reader :currently_processing

    def initialize(concurrent_messages_limit, broker, queue)
      @currently_processing = Set.new
      @maximum_concurrently = concurrent_messages_limit
      @broker = broker
      @run = true
      @fetcher_id = SecureRandom.hex(4)
      @queue = queue
      @queue_name = queue.queue_name
      log_data

      link @broker
      subscribe "free_#{@fetcher_id}", :free_slot
    end

    def run
      while @run
        fetch
        sleep sleep_time
      end
    end

    def stop
      @run = false
      info log_data.merge(at: 'stop')
      terminate
    end

    def fetch
      debug log_data.merge(at: 'fetch', free_slots: available_slots)
      fetch_messages if available_slots?
    rescue => e
      error log_data.merge(at: 'fetch'), e
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

    def free_slot(_, uuid)
      @currently_processing.delete(uuid)
    end

    def log_data
      @log_data ||= {
        component: 'fetcher',
        fetcher_id: @fetcher_id,
        queue: @queue_name
      }
    end

    private

    def available_slots
      @maximum_concurrently - @currently_processing.size
    end

    def available_slots?
      available_slots > 0
    end

    def sleep_time
      @last_fetch_was_empty ? 1 : 0.1
    end
  end
end
