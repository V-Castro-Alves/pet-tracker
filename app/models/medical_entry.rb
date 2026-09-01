class MedicalEntry < ApplicationRecord
  belongs_to :pet
  belongs_to :created_by, class_name: "User"

  scope :chronological, -> { order(entry_date: :desc, created_at: :desc) }

  validates :entry_date, :body, presence: true
  validate :entry_date_cannot_be_in_the_future

  private
    def entry_date_cannot_be_in_the_future
      errors.add(:entry_date, "cannot be in the future") if entry_date.present? && entry_date > Date.current
    end
end
