class BrokenWorker
  include Envoy::Worker

  def process
    fail
  end
end
