# Configure Rails Environment
ENV['RAILS_ENV'] = 'test'

require File.expand_path('../dummy/config/environment.rb',  __FILE__)
require 'rails/test_help'
require 'awesome_print'
require 'ostruct'

Rails.backtrace_cleaner.remove_silencers!

# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

# Load fixtures from the engine
if ActiveSupport::TestCase.method_defined?(:fixture_path=)
  ActiveSupport::TestCase.fixture_path = File.expand_path('../fixtures', __FILE__)
end

require 'database_cleaner'
require 'minitest/rg'
require 'minitest/focus'
require 'minitest-spec-rails'

DatabaseCleaner.strategy = :truncation

class MiniTest::Spec
  before :each do
    DatabaseCleaner.start
  end

  after :each do
    DatabaseCleaner.clean
  end
end

require_relative 'support/mock_queue'
require_relative 'support/mock_broker'
require_relative 'support/mock_dispatcher'
require_relative 'support/worker'
require_relative 'support/broken_worker'

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

Celluloid.start
Celluloid.logger = Logger.new('/tmp/envoy-tests')

Envoy.configure do |config|
  config.aws.access_key = ENV['AWS_ACCESS_KEY']
  config.aws.secret_key = ENV['AWS_SECRET_KEY']
  config.aws.region = 'eu-west-1'
  config.aws.account_id = ENV['AWS_ACCOUNT_ID']
  config.sns.endpoint = "http://#{config.aws.region}.localhost:6061"
  config.sns.protocol = 'cqs'
  config.sqs.endpoint = "http://#{config.aws.region}.localhost:6059"
  config.sqs.protocol = 'cqs'
end
