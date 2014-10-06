$LOAD_PATH.push File.expand_path('../lib', __FILE__)

# Maintain your gem's version:
require 'envoy/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'envoy'
  s.version     = Envoy::VERSION
  s.authors     = ['Lee Henson']
  s.email       = ['lee.m.henson@gmail.com']
  s.homepage    = 'https://github.com/musicglue/envoy'
  s.summary     = 'SQS job consumer'
  s.description = 'SQS job consumer'
  s.license     = 'MIT'

  s.files = Dir['{app,bin,config,db,lib}/**/*', 'MIT-LICENSE', 'Rakefile', 'README.rdoc']
  s.executables = s.files.grep(/^bin\//) { |f| File.basename(f) }
  s.test_files = Dir['test/**/*']
  s.require_paths = ['lib']

  s.add_runtime_dependency 'aws-sdk-core'
  s.add_runtime_dependency 'celluloid', '>= 0.16'
  s.add_runtime_dependency 'middleware'
  s.add_runtime_dependency 'nokogiri'
  s.add_runtime_dependency 'rails', '>= 4.1'
  s.add_runtime_dependency 'timers', '>= 4.0.1'

  s.add_development_dependency 'awesome_print'
  s.add_development_dependency 'bundler', '~> 1.6'
  s.add_development_dependency 'guard'
  s.add_development_dependency 'guard-minitest'
  s.add_development_dependency 'guard-rubocop'
  s.add_development_dependency 'minitest'
  s.add_development_dependency 'minitest-focus'
  s.add_development_dependency 'minitest-rg'
  s.add_development_dependency 'minitest-spec-rails'
  s.add_development_dependency 'pg'
  s.add_development_dependency 'pry-byebug'
  s.add_development_dependency 'rake'
end
