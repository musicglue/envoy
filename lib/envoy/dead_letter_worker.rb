module Envoy
  class DeadLetterWorker
    include Envoy::Worker

    active_record

    def process
      unless DeadLetter.exists?(docket_id: message.id)
        DeadLetter.create!(
          docket_id: message.id,
          message: message.to_h)
      end
    end
  end
end
