class Task < ApplicationRecord
  include PublicIdentifier
  after_commit :refresh_household
  private def refresh_household
    container = household
    container.users.each { |user| Turbo::StreamsChannel.broadcast_refresh_to(user, :tasks) }
  end

  belongs_to :household
  has_one :pet_care_task_detail, dependent: :destroy
  has_one :pet, through: :pet_care_task_detail
  belongs_to :assignee, class_name: "User", optional: true
  has_many :task_occurrences, dependent: :destroy
  has_many :task_reminder_preferences, dependent: :destroy
  validates :title, :starts_on, presence: true
  validates :recurrence, inclusion: { in: %w[once daily weekly] }
  validates :time_zone, inclusion: { in: ActiveSupport::TimeZone.all.map(&:name) }
  validates :local_time, format: { with: /\A([01]\d|2[0-3]):[0-5]\d\z/ }
  validates :kind, inclusion: { in: %w[standard pet_care] }
  validate :valid_relations_and_days
  scope :active, -> { where(archived_at: nil) }
  def occurs_on?(date)
    date >= starts_on && (recurrence == "daily" || (recurrence == "once" && date == starts_on) || (recurrence == "weekly" && weekdays.include?(date.wday)))
  end
  private
    def valid_relations_and_days
      errors.add(:assignee, "must belong to this household") if assignee && !household.users.exists?(id: assignee_id)
      errors.add(:kind, "requires the Pet Care module") if kind == "pet_care" && !household.pet_care_enabled?
      errors.add(:weekdays, "must contain weekdays 0–6") unless weekdays.is_a?(Array) && weekdays.all? { |day| day.is_a?(Integer) && (0..6).cover?(day) } && (recurrence != "weekly" || weekdays.any?)
    end
end
