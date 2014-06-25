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
      while @run do
        begin
          fetch
        rescue => e
          error e.inspect
        end
        sleep(1)
      end
    end

    def stop
      @run = false
      info "[#{@queue.queue_name}] Stopping..."
      terminate
    end

    def fetch
      info "[#{@queue.queue_name}] Available Slots: #{available_slots}"
      fetch_messages if available_slots?
    end

    def process(message)
      message = Envoy::SQS::Message.new(message, @queue, @fetcher_id)
      if message.alive?
        @currently_processing << message.id
        @broker.process_message(message)
      end
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
  end
end
