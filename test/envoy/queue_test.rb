# require_relative '../test_helper'

# describe Envoy::Queue do
#   before do
#     @sqs = StubSqs.new

#     @config = Envoy::Configuration.new
#     @config.add_queue 'queue-1'
#     @config.add_queue 'queue-2'

#     @queue_1 = Envoy::Queue.new 'queue-1', @sqs, @config
#     @queue_2 = Envoy::Queue.new 'queue-2', @sqs, @config
#   end

#   it 'bah' do
#     @queue_1.async.start
#     @queue_2.async.start

#     Celluloid::Notifications.notifier.publish 'message_processed_on_queue-1', SecureRandom.uuid

#     @queue_1.stop
#     @queue_2.stop
#   end
# end
