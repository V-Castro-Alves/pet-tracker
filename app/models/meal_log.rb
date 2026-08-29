class MealLog < ApplicationRecord
  belongs_to :pet
  belongs_to :meal_slot
  belongs_to :logged_by_user, class_name: "User"
  belongs_to :duplicate_of, class_name: "MealLog", optional: true
  has_many :duplicate_logs, class_name: "MealLog", foreign_key: :duplicate_of_id, dependent: :nullify

  enum :status, { fed: "fed", skipped: "skipped" }, validate: true

  validates :scheduled_for, presence: true
  validates :actual_amount_g, numericality: { greater_than: 0 }, if: :fed?
  validates :actual_time, presence: true, if: :fed?
  validates :actual_amount_g, :actual_time, absence: true, if: :skipped?
  validate :slot_belongs_to_pet

  scope :chronological, -> { order(scheduled_for: :desc, created_at: :desc) }

  private
    def slot_belongs_to_pet
      errors.add(:meal_slot, "must belong to the same pet") if meal_slot && pet && meal_slot.pet_id != pet_id
    end
end
