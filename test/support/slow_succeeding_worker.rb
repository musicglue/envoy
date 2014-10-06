class SlowSucceedingWorker
  include Envoy::Worker

  def process
    sleep 1
  end
end
