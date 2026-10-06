class HouseholdInvitation < ApplicationRecord
  belongs_to :household
  has_secure_token :token
  before_validation -> { self.expires_at ||= 7.days.from_now }, on: :create
  normalizes :email, with: ->(value) { value.strip.downcase.presence }
  def accept!(user)
    with_lock do
      raise ActiveRecord::RecordInvalid, self if accepted_at || expires_at <= Time.current || (email.present? && email != user.email_address)
      household.memberships.find_or_create_by!(user: user)
      update!(accepted_at: Time.current)
    end
  end
end
