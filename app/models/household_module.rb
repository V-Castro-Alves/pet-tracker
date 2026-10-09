class HouseholdModule < ApplicationRecord
  KEYS = %w[pet_care].freeze

  belongs_to :household
  belongs_to :enabled_by, class_name: "User", inverse_of: :enabled_household_modules

  validates :key, inclusion: { in: KEYS }, uniqueness: { scope: :household_id }
  validates :enabled_at, presence: true
end
