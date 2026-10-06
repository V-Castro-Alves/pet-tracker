class FeedingEntry < ApplicationRecord
  include PublicIdentifier
  belongs_to :pet
  belongs_to :task_occurrence, optional: true
  belongs_to :actor, class_name: "User"
  belongs_to :credited_user, class_name: "User"
  validates :amount_g, numericality: { greater_than: 0 }
  validates :fed_at, presence: true
end
