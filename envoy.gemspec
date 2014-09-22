$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "envoy/version"

Gem::Specification.new do |spec|
  spec.name          = "envoy"
  spec.version       = Envoy::VERSION
  spec.authors       = ["Adam Carlile", "Lee Henson"]
  spec.email         = ["adam@benchmedia.co.uk", "lee.m.henson@gmail.com"]
  spec.summary       = %q{SQS-based job processing}
  spec.description   = %q{SQS-based job processing}
  spec.homepage      = "https://github.com/musicglue/envoy"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = Dir["test/**/*"]

  spec.add_runtime_dependency 'aws-sdk-core'
  spec.add_runtime_dependency 'celluloid', ">= 0.16"
  spec.add_runtime_dependency 'middleware'
  spec.add_runtime_dependency 'nokogiri'
  spec.add_runtime_dependency "rails", ">= 4.1"
  spec.add_runtime_dependency 'timers', '>= 4.0.1'

  spec.add_development_dependency "awesome_print"
  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "database_cleaner"
  spec.add_development_dependency "guard"
  spec.add_development_dependency "guard-minitest"
  spec.add_development_dependency "guard-rubocop"
  spec.add_development_dependency "pg"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "minitest-focus"
  spec.add_development_dependency "minitest-rg"
  spec.add_development_dependency "minitest-spec-rails"
  spec.add_development_dependency "simplecov"
end
