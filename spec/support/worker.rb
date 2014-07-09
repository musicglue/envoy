class Worker
  include Envoy::Worker

  def process
    # Noop, just to test the included module
  end
end
