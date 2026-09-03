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

  def read?
    read_at.present?
  end
end
