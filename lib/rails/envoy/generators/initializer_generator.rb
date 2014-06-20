require "rails/generators/named_base"

module Envoy
  class InitializerGenerator < Rails::Generator::Base

    def copy_initializer_file
      copy_file "initializer.rb", "config/initializers/envoy.rb"
    end

  end
end
