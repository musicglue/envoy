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
      @queues[value.to_s.underscore.to_sym]
    end

    def each(&block)
      queues.each(&block)
    end

    def add_queue(name, options={})
      @queues[name.to_s.underscore.to_sym] = SQS::Queue.new(name.to_s.underscore.to_sym, options)
    end

  end
end
