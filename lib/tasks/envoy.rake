namespace :envoy do
  namespace :dead_letters do
    desc "Retry a dead letter (options: ID=docket_id)."
    task :retry => :environment do
      Envoy::DeadLetterRetrier.new.retry DeadLetter.where(docket_id: ENV['ID'])
    end

    desc "Retries all the dead letters."
    task :retry_all => :environment do
      Envoy::DeadLetterRetrier.new.retry DeadLetter.all
    end
  end
end
