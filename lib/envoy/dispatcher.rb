module Envoy
  class Dispatcher
    include Celluloid

    def process(workflow_klass, message)
      @worker = workflow_klass.new(message)
      @worker.async.safely_process
    end
  end
end
