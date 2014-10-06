namespace :envoy do
  namespace :build do
    desc 'Builds policies, topics and queues defined by the initializer.'
    task all: %i(environment topics queues policies) do

    end

    desc 'Builds the application policies defined by the initializer.'
    task policies: :environment do
      builder.build_policies
    end

    desc 'Builds the queues defined by the initializer.'
    task queues: :environment do
      builder.build_queues
    end

    desc 'Builds the topics defined by the initializer.'
    task topics: :environment do
      builder.build_topics
    end

    private

    def builder
      Envoy::InfrastructureBuilder.new Envoy.config
    end
  end

  namespace :dead_letters do
    desc 'Retry a dead letter (options: ID=docket_id).'
    task retry: :environment do
      Envoy::DeadLetterRetrier.new.retry DeadLetter.where(docket_id: ENV['ID'])
    end

    desc 'Retries all the dead letters.'
    task retry_all: :environment do
      Envoy::DeadLetterRetrier.new.retry DeadLetter.all
    end
  end
end
