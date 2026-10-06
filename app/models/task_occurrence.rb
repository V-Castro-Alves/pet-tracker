class TaskOccurrence < ApplicationRecord
  include PublicIdentifier
  after_commit :refresh_household
  private def refresh_household
    container = task.household
    container.users.each { |user| Turbo::StreamsChannel.broadcast_refresh_to(user, :tasks) }
  end

  has_one :feeding_entry, dependent: :nullify
  belongs_to :task
  belongs_to :assignee, class_name: "User", optional: true
  belongs_to :actor, class_name: "User", optional: true
  belongs_to :credited_user, class_name: "User", optional: true
  validates :status, inclusion: { in: %w[pending completed skipped] }
  validates :local_date, uniqueness: { scope: :task_id }
  validates :scheduled_at, presence: true
end
