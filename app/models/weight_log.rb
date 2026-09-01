class WeightLog < ApplicationRecord
  belongs_to :pet

  scope :chronological, -> { order(logged_at: :desc, created_at: :desc) }

  validates :weight_kg, numericality: { greater_than: 0 }
  validates :logged_at, presence: true, uniqueness: { scope: :pet_id, message: "already has a weight entry" }
  validate :logged_at_cannot_be_in_the_future

  private
    def logged_at_cannot_be_in_the_future
      errors.add(:logged_at, "cannot be in the future") if logged_at.present? && logged_at > Date.current
    end
end
