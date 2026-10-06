class SchedulerHeartbeat < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  def healthy?
    completed_at.present? && completed_at > 5.minutes.ago && last_error.nil?
  end
end
