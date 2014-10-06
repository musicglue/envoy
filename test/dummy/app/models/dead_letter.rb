class DeadLetter < ActiveRecord::Base
  validates :docket_id, presence: true
  validates :message, presence: true
end
