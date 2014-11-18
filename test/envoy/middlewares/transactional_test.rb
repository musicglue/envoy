require_relative '../../test_helper'
require_relative '../../../lib/envoy/middlewares/transactional'

describe Envoy::Middlewares::Transactional do
  class MiddlewareTestWorker
    include Envoy::Worker

    transactional isolation: :repeatable_read, tries: 3, on_error: :store_error

    def initialize error_to_raise, tried_callback, on_error_callback
      @error_to_raise = error_to_raise
      @tried_callback = tried_callback
      @on_error_callback = on_error_callback
    end

    def process
      @tried_callback.call
      fail @error_to_raise
    end

    def store_error error
      @on_error_callback.call error
    end
  end

  before do
    @error = ActiveRecord::RecordNotUnique.new('Foo')
    @tries = 0

    @tried_callback = proc do
      @tries += 1
    end

    @on_error_callback = proc do |error|
      @callback_error = error
    end

    @worker = MiddlewareTestWorker.new @error, @tried_callback, @on_error_callback
    @worker.process_for_watchdog rescue @error.class
  end

  it 'calls the error callback when a retriable error is encountered' do
    @callback_error.must_equal @error
  end

  it 'passes through other retriable options' do
    @tries.must_equal 3
  end
end
