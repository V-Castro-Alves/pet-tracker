class MealReminderPreference < ApplicationRecord
  WEEKDAYS = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday].freeze
  TIMING_OPTIONS = [ [ "No notifications", "off" ], [ "On meal time", "0" ],
    [ "After 15 min not logged", "15" ], [ "After 30 min not logged", "30" ],
    [ "After 60 min not logged", "60" ], [ "Custom time", "custom" ] ].freeze

  validate :valid_weekday_delays

  def delay_for(date)
    return unless enabled?
    weekday_delays.fetch(date.wday.to_s, delay_minutes)
  end

  def weekday_delay(day)
    weekday_delays.fetch(day.to_s, enabled? ? delay_minutes : nil)
  end

  def weekday_timing(day)
    delay = weekday_delay(day)
    return "off" if delay.nil?
    [ 0, 15, 30, 60 ].include?(delay) ? delay.to_s : "custom"
  end

  def weekdays=(settings)
    self.enabled = true
    self.weekday_delays = settings.to_h.transform_values do |setting|
      timing = setting["timing"]
      value = timing == "custom" ? setting["minutes"] : timing
      timing == "off" ? nil : (value.to_s.match?(/\A\d+\z/) ? value.to_i : value)
    end
  end

  belongs_to :meal_slot
  belongs_to :user

  validates :user_id, uniqueness: { scope: :meal_slot_id }
  validates :enabled, inclusion: { in: [ true, false ] }
  validates :delay_minutes, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 1440 }
  private
    def valid_weekday_delays
      unless weekday_delays.is_a?(Hash) && weekday_delays.all? { |day, delay| day.in?(%w[0 1 2 3 4 5 6]) && (delay.nil? || (delay.is_a?(Integer) && delay.between?(0, 1440))) }
        errors.add(:weekday_delays, "must contain weekdays with whole-minute delays between 0 and 1440")
      end
    end
end
