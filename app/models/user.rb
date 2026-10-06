class User < ApplicationRecord
  include PublicIdentifier
  has_many :memberships, dependent: :destroy
  has_many :households, through: :memberships
  has_many :api_tokens, dependent: :destroy
  has_secure_password
  has_many :meal_reminder_preferences, dependent: :destroy
  has_many :sessions, dependent: :destroy
  has_many :pet_users, dependent: :destroy
  has_many :pets, through: :pet_users
  has_many :meal_logs, foreign_key: :logged_by_user_id, dependent: :restrict_with_error, inverse_of: :logged_by_user
  has_many :created_pet_invites, class_name: "PetInvite", foreign_key: :created_by_id, dependent: :restrict_with_error, inverse_of: :created_by
  has_many :accepted_pet_invites, class_name: "PetInvite", foreign_key: :accepted_by_id, dependent: :nullify, inverse_of: :accepted_by
  has_many :medical_entries, foreign_key: :created_by_id, dependent: :restrict_with_error, inverse_of: :created_by
  has_many :notifications, dependent: :destroy
  has_many :push_subscriptions, dependent: :destroy

  def pets
    Pet.where(household_id: households.where(pets_enabled: true).select(:id)).or(Pet.where(household_id: nil, id: pet_users.select(:pet_id)))
  end

  normalizes :email_address, with: ->(email) { email.strip.downcase }

  validates :email_address, presence: true, uniqueness: { case_sensitive: false }
  validates :name, presence: true
  validates :time_zone,
    presence: true,
    inclusion: { in: ActiveSupport::TimeZone.all.map(&:name), message: "is not a valid time zone" }
end
