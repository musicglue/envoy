# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "envoy"
  spec.version       = '1.0.1'
  spec.authors       = ["Adam Carlile"]
  spec.email         = ["adam@benchmedia.co.uk"]
  spec.summary       = %q{Bringing peace to the SQS consumption world}
  spec.description   = %q{Way better then Tony Blair at bringing peace to Iraq}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency 'activesupport', "~> 4.1"
  spec.add_runtime_dependency 'celluloid', "~> 0.16.0"
  spec.add_runtime_dependency 'aws-sdk-core'
  spec.add_runtime_dependency 'middleware'
  spec.add_runtime_dependency 'newrelic_rpm', '>= 3.9.3.241'
  spec.add_runtime_dependency 'nokogiri'
  spec.add_runtime_dependency 'thor'
  spec.add_runtime_dependency 'timers', '>= 4.0.1'
  spec.add_runtime_dependency 'uuid', '~> 2.3'

  spec.add_development_dependency "awesome_print"
  spec.add_development_dependency "guard"
  spec.add_development_dependency "guard-minitest"
  spec.add_development_dependency "guard-rubocop"
  spec.add_development_dependency "vcr"
  spec.add_development_dependency "minitest-vcr"
  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "minitest-focus"
  spec.add_development_dependency "minitest-rg"
  spec.add_development_dependency "webmock"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "simplecov"
end
