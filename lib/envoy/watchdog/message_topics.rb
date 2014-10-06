module Envoy
  class Watchdog
    MessageTopics = Struct.new :success, :failure, :heartbeat
  end
end
