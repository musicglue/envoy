require_relative 'test_helper'

describe Envoy::SQS::Queue do
  let(:queue_name) { 'test-queue' }
  let(:queue_config) { Envoy::Configuration::QueueConfiguration.new queue_name }

  describe 'with a queue on sqs' do
    before do
      VCR.insert_cassette self.class.name.vcr_path(self, name)
    end

    after do
      VCR.eject_cassette
    end

    let(:queue) do
      Envoy::SQS::Queue.new(queue_config, 'http://eu-west-1.localhost:6059')
    end

    it 'should return an sqs object' do
      queue.sqs.wont_be_nil
    end

    it 'should return an aws arn' do
      queue.arn.must_match(/#{queue_name}/)
    end

    it 'should return the correct uri to the inbound queue' do
      queue.inbound_queue.must_match(/#{queue_name}/)
    end

    it 'should be able to clear the cache' do
      queue.refresh
      queue.instance_variable_get('@arn').must_be_nil
    end

    describe 'with a message in the queue' do
      let(:message_json) { SQS_MESSAGE_HASH.to_json }
      let(:messages)     { queue.pop(1) }

      before do
        queue.sqs.send_message(queue_url: queue.inbound_queue, message_body: message_json)
      end

      it 'get a message from the queue' do
        messages.wont_be_nil
      end

      it 'extends the timeout' do
        queue.extend_invisibility(messages.first.receipt_handle, 30)
        queue.pop(10).map(&:receipt_handle).wont_include(messages.first.receipt_handle)
      end

      it 'deletes the message' do
        queue.delete_message(messages.first.receipt_handle)
        queue.pop(10).map(&:receipt_handle).wont_include(messages.first.receipt_handle)
      end
    end
  end
end
