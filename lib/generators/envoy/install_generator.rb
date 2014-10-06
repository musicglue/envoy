require 'rails/generators/named_base'
require 'rails/generators/active_record/migration'

module Envoy
  class InstallGenerator < Rails::Generators::Base
    include ActiveRecord::Generators::Migration

    desc 'Installs models and initializers for Envoy'

    source_root File.expand_path('../templates', __FILE__)

    def copy_initializer_file
      copy_file 'initializer.rb', 'config/initializers/envoy.rb'
      copy_file 'dead_letter.rb', 'app/models/dead_letter.rb'

      migration_template 'create_dead_letters_migration.rb',
                         'db/migrate/envoy_create_dead_letters.rb'
    end
  end
end
