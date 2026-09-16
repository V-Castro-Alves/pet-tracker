class Notification < ApplicationRecord
  KINDS = %w[meal_reminder meal_unresolved food_low vaccine_due].freeze

  belongs_to :user
  belongs_to :pet, optional: true

  validates :kind, inclusion: { in: KINDS }
  validates :title, :body, :path, :deduplication_key, presence: true
  validates :deduplication_key, uniqueness: { scope: :user_id }

  scope :recent_first, -> { order(created_at: :desc) }
  scope :unread, -> { where(read_at: nil) }

  after_create_commit -> { DeliverNotificationJob.perform_later(self) }

  after_create_commit -> { self.class.broadcast_for(user) }
  after_update_commit -> { self.class.broadcast_for(user) }, if: :saved_change_to_read_at?

  def self.broadcast_for(user)
    Turbo::StreamsChannel.broadcast_replace_to(user, :notifications,
      target: "notification-list", partial: "notifications/list",
      locals: { notifications: user.notifications.includes(:pet).recent_first })
    Turbo::StreamsChannel.broadcast_replace_to(user, :notifications,
      target: "notification-badge", partial: "notifications/badge", locals: { user: user })
    Turbo::StreamsChannel.broadcast_replace_to(user, :notifications,
      target: "notification-actions", partial: "notifications/actions", locals: { user: user })
  end

  def read?
    read_at.present?
  end
end
