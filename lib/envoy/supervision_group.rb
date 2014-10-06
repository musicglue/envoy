module Envoy
  class SupervisionGroup
    include Envoy::Logging

    def initialize config, sqs
      @config = config
      @group = Celluloid::SupervisionGroup.new
      @sqs = sqs
      @log_data = { component: 'supervision_group' }
      @actor_names = []
    end

    def start
      add_custom_actors @config.celluloid.actors
      add_queues
    end

    def stop
      @actor_names.each do |name|
        info @log_data.merge at: 'stop', actor: name
        actor = Celluloid::Actor[name]

        begin
          actor.async.stop if actor.respond_to? :stop
        rescue Celluloid::DeadActorError
        end
      end

      sleep 7 # give the actors as much time as possible to shutdown gracefully
    end

    private

    def add_custom_actors actors
      actors.each do |actor|
        debug @log_data.merge at: 'supervise_actor', actor: actor
        actor_name = "#{actor.to_s.underscore}_custom_actor"
        supervise_and_start actor_name, actor
      end
    end

    def add_queues
      queues = [@config.dead_letter_queue, @config.queues].flatten.compact

      queues.each do |queue|
        actor_name = "#{queue.name.to_s.underscore}_queue_actor"
        supervise_and_start actor_name, Envoy::Queue, queue.name, @sqs, @config
      end
    end

    def supervise_and_start name, *args
      @group.supervise_as(name, *args).async.start
      @actor_names << name
    end
  end
end
