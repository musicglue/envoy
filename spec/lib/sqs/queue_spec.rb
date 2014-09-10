require 'spec_helper'
require 'pry'

describe Envoy::SQS::Queue, :vcr do

  let(:queue_name) { 'test-queue' }

  describe 'with a queue on s3' do
    let(:described_class) { Envoy::SQS::Queue.new(queue_name,  endpoint: 'http://localhost:6059') }

    it 'should return an s3 connection object' do
      described_class.connection.wont_be_nil
    end

    it "it should return it's AWS ARN" do
      described_class.arn.must_match(/#{queue_name}/)
    end

    it 'should return the correct uri to the inbound queue' do
      described_class.inbound_queue.must_match(/#{queue_name}/)
    end

    it 'should be able to clear the cache' do
      described_class.refresh
      described_class.instance_variable_get('@arn').must_be_nil
    end

    it 'should be able to tell if its AWS or CMB' do
      described_class.cmb?.must_equal true
    end

    describe 'with a message in the queue' do

      let(:message_json) { SQS_MESSAGE_HASH.to_json }
      let(:messages)     { described_class.pop(1) }

      before do
        described_class.connection.send_message(queue_url: described_class.inbound_queue, message_body: message_json)
      end

      it 'get a message from the queue' do
        messages.wont_be_nil
      end

      it 'extends the timeout' do
        described_class.extend_invisibility(messages.first.receipt_handle, 30)
        described_class.pop(10).map(&:receipt_handle).wont_include(messages.first.receipt_handle)
      end

      it 'deletes the message' do
        described_class.delete_message(messages.first.receipt_handle)
        described_class.pop(10).map(&:receipt_handle).wont_include(messages.first.receipt_handle)
      end
    end

  end
end
