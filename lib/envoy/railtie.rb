require 'rails'

module Envoy
  class Railtie < Rails::Railtie
    rake_tasks do
      load File.expand_path('../../tasks/envoy.rake', __FILE__)
    end
  end
end
