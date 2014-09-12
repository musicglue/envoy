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

require 'awesome_print'
require 'minitest/autorun'
require 'webmock/minitest'
require 'minispec-metadata'
require 'vcr'
require 'minitest-vcr'
require 'webmock'

require 'envoy'

require_relative 'support/mock_queue'
require_relative 'support/mock_broker'
require_relative 'support/mock_dispatcher'
require_relative 'support/worker'
require_relative 'support/broken_worker'

# If VCR cassettes stop working because of an aws-sdk-core gem update, you'll need to:
#
# - fire up cmb
# - create a new account and paste the access + secret keys into the config below
# - create a test-queue-test

VCR.configure do |config|
  config.cassette_library_dir = 'spec/fixtures/cassettes'
  config.hook_into :webmock
end

MinitestVcr::Spec.configure!

class StubSocket; attr_accessor :continue_timeout end

Envoy.configure do |config|
  config.aws.credentials = {
    access_key_id: 'A0O8YNPWVQ81JJNXI8Q7',
    secret_access_key: 'Q+goNGK6Op7RtYuyDWIZWYmGWp/WVztczg4VeY+F'
  }
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
