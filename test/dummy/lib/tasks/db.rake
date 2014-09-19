namespace :db do
  desc 'Enables all required pg extensions'
  task :enable_extensions => :environment do
    %w(plpgsql uuid-ossp).each do |name|
      ActiveRecord::Base.connection.enable_extension name
    end
  end
end
