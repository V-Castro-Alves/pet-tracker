class PetCareTaskDetail < ApplicationRecord
  CARE_TYPES = %w[feeding medication walking grooming vaccination custom].freeze

  belongs_to :task
  belongs_to :pet

  validates :care_type, inclusion: { in: CARE_TYPES }
  validates :amount_g, numericality: { greater_than: 0 }, allow_nil: true
  validate :pet_belongs_to_task_household
  validate :amount_matches_care_type

  private
    def pet_belongs_to_task_household
      errors.add(:pet, "must belong to this household") if pet && task && pet.household_id != task.household_id
    end

    def amount_matches_care_type
      errors.add(:amount_g, "is only available for feeding tasks") if amount_g && care_type != "feeding"
    end
end
