class MealSlot < ApplicationRecord
  belongs_to :pet
  has_many :meal_logs, dependent: :destroy

  scope :active, -> { where(active: true) }
  scope :chronological, -> { order(:scheduled_time, :name) }

  validates :name, :scheduled_time, presence: true
  validates :default_amount_g, numericality: { greater_than: 0 }
  validates :scheduled_time,
    uniqueness: { scope: :pet_id, conditions: -> { where(active: true) }, message: "already has an active meal at this time" },
    if: :active?
end
