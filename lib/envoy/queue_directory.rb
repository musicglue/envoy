module Envoy
  class QueueDirectory
    include Enumerable

    def initialize()
      @queues = {}
    end

    def queues
      @queues.values
    end

    def [](value)
      @queues[value]
    end

    def each(&block)
      queues.each(&block)
    end

    def add_queue(name, options={})
      @queue[name] = SQS::Queue.new(name, options)
    end

  end
end
