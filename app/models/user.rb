class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :pet_users, dependent: :destroy
  has_many :pets, through: :pet_users
  has_many :meal_logs, foreign_key: :logged_by_user_id, dependent: :restrict_with_error, inverse_of: :logged_by_user
  has_many :created_pet_invites, class_name: "PetInvite", foreign_key: :created_by_id, dependent: :restrict_with_error, inverse_of: :created_by
  has_many :accepted_pet_invites, class_name: "PetInvite", foreign_key: :accepted_by_id, dependent: :nullify, inverse_of: :accepted_by
  has_many :medical_entries, foreign_key: :created_by_id, dependent: :restrict_with_error, inverse_of: :created_by

  normalizes :email_address, with: ->(email) { email.strip.downcase }

  validates :email_address, presence: true, uniqueness: { case_sensitive: false }
  validates :name, presence: true
  validates :time_zone,
    presence: true,
    inclusion: { in: ActiveSupport::TimeZone.all.map(&:name), message: "is not a valid time zone" }
end
