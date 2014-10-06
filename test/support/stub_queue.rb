class StubQueue < Envoy::Queue
  def acknowledge_message _topic, id
    acknowledged_messages << id
  end

  def acknowledged_messages
    @acknowledged_messages ||= []
  end

  def message_heartbeat _topic, id
    message_heartbeats << id
  end

  def message_heartbeats
    @message_heartbeats ||= []
  end

  def unacknowledge_message _topic, id
    unacknowledged_messages << id
  end

  def unacknowledged_messages
    @unacknowledged_messages ||= []
  end
end
