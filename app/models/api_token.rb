class ApiToken < ApplicationRecord
  SCOPES = %w[tasks:read tasks:write reminders:write pets:read].freeze
  belongs_to :household
  belongs_to :user
  validates :name, :expires_at, :token_digest, presence: true
  validate { errors.add(:scopes, "are invalid") unless scopes.is_a?(Array) && scopes.any? && (scopes - SCOPES).empty? }
  def self.issue!(attributes)
    raw = SecureRandom.urlsafe_base64(32)
    [ create!(attributes.merge(token_digest: Digest::SHA256.hexdigest(raw))), raw ]
  end
  def self.authenticate(raw)
    token = find_by(token_digest: Digest::SHA256.hexdigest(raw))
    token if token && !token.revoked_at && token.expires_at > Time.current && token.household.users.exists?(id: token.user_id)
  end
end
