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

require 'minitest/rg'
require 'minitest/focus'
require 'minitest-spec-rails'
require 'pry-byebug'
require 'vcr'
require 'webmock'

VCR.configure do |c|
  c.cassette_library_dir = 'test/cassettes'
  c.hook_into :webmock
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
  config.aws.access_key = 'WE6BN6AWQLJ47G9Z540E'
  config.aws.secret_key = 'LNsde4uYRA5eeV8e5RWAL0LRO1/vMmF2DXg94qMs'
  config.aws.region = 'eu-west-1'
  config.aws.account_id = '411404999819'

  config.sns.endpoint = "http://eu-west-1.localhost:6061"
  config.sns.protocol = 'cqs'
  config.sqs.endpoint = "http://eu-west-1.localhost:6059"
  config.sqs.protocol = 'cqs'
end

class String
  def vcr_path(example, spec_name)
    self.scan(/^(.*?)::[#a-z]/) do |class_names|
      class_name = class_names.flatten.first

      if class_name.nil?
        @path = example.class.name.prep
      else
        @path = example.class.name.gsub(class_name, "").prep.unshift(class_name)
      end
    end

    @path.push(spec_name).join("/") unless @path.nil?
  end

  def prep
    split("::").map {|e| e.sub(/[^\w]*$/, "")}.reject(&:empty?) - ["vcr"]
  end
end
