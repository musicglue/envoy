require 'spec_helper'
require 'pry'
describe Envoy::QueueDirectory do

  let(:described_class) { Envoy::QueueDirectory.new }

  describe 'adding string named queues' do
    let(:queue_name) { 'this-is-a-queue' }

    before do
      described_class.add_queue queue_name
    end

    it 'should return the queue from the directoy' do
      described_class[queue_name].queue_name.must_match(/#{queue_name}/)
    end

    describe 'queue accessors' do

      it 'should be enumerable' do
        described_class.count.must_equal 1
      end

    end

  end

  describe 'adding symbol named queues' do
    let(:queue_name) { :this_is_a_queue }

    before do
      described_class.add_queue queue_name
    end

    it 'should return the queue from the directoy' do
      described_class[queue_name].queue_name.must_match(/#{queue_name.to_s.dasherize}/)
    end

  end

end
