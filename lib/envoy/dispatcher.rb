module AssetRefinery
  class Dispatcher
    include Celluloid
    include Celluloid::Logger
    include Celluloid::Notifications

    def process(workflow_klass, message)
      @worker = workflow_klass.new(message)
      @worker.async.process
    end
  end
end
