module MiniTest
  class Spec
    before :each do
      Celluloid.shutdown
      Celluloid.boot
    end
  end
end

module ActiveSupport
  class TestCase
    before :each do
      Celluloid.shutdown
      Celluloid.boot
    end
  end
end

Celluloid.log_actor_crashes = false
Celluloid.logger = Logger.new(File.expand_path '../../test.log', __FILE__)
Celluloid.shutdown_timeout = 1
