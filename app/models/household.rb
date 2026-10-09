class Household < ApplicationRecord
  include PublicIdentifier
  has_many :memberships, dependent: :destroy
  has_many :users, through: :memberships
  has_many :tasks, dependent: :destroy
  has_many :pets, dependent: :restrict_with_error
  has_many :household_modules, dependent: :destroy
  has_many :household_invitations, dependent: :destroy
  has_many :api_tokens, dependent: :destroy
  has_many :webhook_endpoints, dependent: :destroy
  has_many :domain_events, dependent: :destroy
  validates :name, presence: true
  validates :time_zone, inclusion: { in: ActiveSupport::TimeZone.all.map(&:name) }
  def administered_by?(user)
    memberships.exists?(user: user, admin: true)
  end

  def module_enabled?(key)
    household_modules.exists?(key: key)
  end

  def pet_care_enabled?
    module_enabled?("pet_care")
  end
end
