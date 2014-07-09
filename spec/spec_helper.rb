ENV['ENVOY_ENV'] = 'test'
lib = File.expand_path '../../lib', __FILE__
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'rubygems'
require 'bundler/setup'

require 'simplecov'
SimpleCov.start

Bundler.require(:default, :test)
Celluloid.start
Celluloid.logger = nil

require 'minitest/autorun'
require 'webmock/minitest'
require 'minispec-metadata'
require 'vcr'
require 'minitest-vcr'
require 'webmock'

require 'envoy'

require 'support/mock_queue'
require 'support/mock_broker'
require 'support/worker'
require 'support/broken_worker'

VCR.configure do |config|
  config.cassette_library_dir = 'spec/fixtures/cassettes'
  config.hook_into :webmock
end

MinitestVcr::Spec.configure!

class StubSocket; attr_accessor :continue_timeout end

Envoy.configure do |config|
  config.aws.credentials = {  access_key_id: '6AADEZ8OTKNF30O7SU96',
                              secret_access_key: 'siRiBWXfYknZ/JZLYwy2KwWKpc4/u99vXWEv3y7F' }
  config.queue = MockQueue
end

SQS_MESSAGE_HASH = {
  'header' => {
    'type' => 'generate_zip_file'
  },
  'body' => {
    'files' => [{ 'bucket' => 'aws-test-bucket', 'path' => 'test-path.jpg' }],
    'destination' => {
      'bucket' => 'aws-test-bucket',
      'path' => 'final-asset.zip'
    }
  }
}
