class Vaccine < ApplicationRecord
  DUE_SOON_WINDOW = 7.days

  belongs_to :pet

  scope :by_due_date, -> { order(Arel.sql("next_due_date IS NULL, next_due_date ASC, date_given DESC")) }

  validates :name, :date_given, presence: true
  validate :date_given_cannot_be_in_the_future
  validate :due_date_cannot_precede_given_date

  def due_status(on: Date.current)
    return :none if next_due_date.blank?
    return :overdue if next_due_date < on
    return :due_soon if next_due_date <= on + DUE_SOON_WINDOW

    :current
  end

  private
    def date_given_cannot_be_in_the_future
      errors.add(:date_given, "cannot be in the future") if date_given.present? && date_given > Date.current
    end

    def due_date_cannot_precede_given_date
      return if next_due_date.blank? || date_given.blank? || next_due_date >= date_given

      errors.add(:next_due_date, "cannot be before the date given")
    end
end
