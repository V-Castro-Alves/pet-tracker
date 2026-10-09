class User < ApplicationRecord
  include PublicIdentifier
  has_many :memberships, dependent: :destroy
  has_many :households, through: :memberships
  has_many :api_tokens, dependent: :destroy
  has_many :enabled_household_modules, class_name: "HouseholdModule", foreign_key: :enabled_by_id, dependent: :restrict_with_error, inverse_of: :enabled_by
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :medical_entries, foreign_key: :created_by_id, dependent: :restrict_with_error, inverse_of: :created_by
  has_many :notifications, dependent: :destroy
  has_many :push_subscriptions, dependent: :destroy

  def pets
    Pet.where(household_id: households.joins(:household_modules).where(household_modules: { key: "pet_care" }).select(:id))
  end

  normalizes :email_address, with: ->(email) { email.strip.downcase }

  validates :email_address, presence: true, uniqueness: { case_sensitive: false }
  validates :name, presence: true
  validates :time_zone,
    presence: true,
    inclusion: { in: ActiveSupport::TimeZone.all.map(&:name), message: "is not a valid time zone" }
end
