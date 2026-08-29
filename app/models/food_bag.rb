class FoodBag < ApplicationRecord
  belongs_to :pet

  scope :active, -> { where(ended_at: nil) }
  scope :recent_first, -> { order(started_at: :desc) }

  validates :total_weight_g, numericality: { greater_than: 0 }
  validates :remaining_weight_g, numericality: true
  validates :low_stock_percentage, numericality: { greater_than: 0, less_than_or_equal_to: 100 }
  validates :started_at, presence: true

  def low_stock_threshold_g
    total_weight_g * low_stock_percentage / 100
  end

  def low_stock?
    remaining_weight_g <= low_stock_threshold_g
  end

  def empty?
    remaining_weight_g <= 0
  end

  def percentage_remaining
    ((remaining_weight_g / total_weight_g) * 100).clamp(0, 100)
  end

  def estimated_days_remaining
    daily_average = pet.average_daily_consumption_g
    return if daily_average <= 0

    [ remaining_weight_g / daily_average, 0 ].max.floor
  end
end
