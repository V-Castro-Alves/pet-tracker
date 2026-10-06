class TaskReminderPreference < ApplicationRecord
  belongs_to :task
  belongs_to :user
  validates :user_id, uniqueness: { scope: :task_id }
  validates :delay_minutes, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 1440 }
  validate do
    unless weekday_delays.is_a?(Hash) && weekday_delays.all? { |day, delay| day.in?(%w[0 1 2 3 4 5 6]) && (delay.nil? || (delay.is_a?(Integer) && (0..1440).cover?(delay))) }
      errors.add(:weekday_delays, "must map weekdays to minutes or null")
    end
  end
  def self.for_user(task:, user:)
    preference = find_or_initialize_by(task: task, user: user)
    preference.enabled = task.assignee_id.nil? || task.assignee_id == user.id if preference.new_record?
    preference
  end
  def delay_for(date)
    return unless enabled?
    weekday_delays.fetch(date.wday.to_s, delay_minutes)
  end
end
