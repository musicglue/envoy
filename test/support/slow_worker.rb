class SlowWorker
  include Envoy::Worker

  def process
    Kernel.sleep 3
  end
end
