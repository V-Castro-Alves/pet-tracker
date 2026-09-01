class PetInvite < ApplicationRecord
  EXPIRATION = 7.days

  has_secure_token :invite_token, length: 32

  belongs_to :pet
  belongs_to :created_by, class_name: "User"
  belongs_to :accepted_by, class_name: "User", optional: true

  normalizes :invited_email, with: ->(email) { email.strip.downcase }

  validates :expires_at, presence: true
  validates :invited_email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true

  scope :pending, -> { where(accepted_at: nil).where(expires_at: Time.current..) }
  scope :recent_first, -> { order(created_at: :desc) }

  def expired?
    expires_at <= Time.current
  end

  def accepted?
    accepted_at.present?
  end

  def available_to?(user)
    invited_email.blank? || invited_email == user.email_address
  end
end
