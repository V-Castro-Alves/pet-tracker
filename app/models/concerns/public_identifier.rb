module PublicIdentifier
  extend ActiveSupport::Concern
  included do
    before_validation -> { self.public_id ||= SecureRandom.uuid }, on: :create
    validates :public_id, presence: true, uniqueness: true
  end
  def to_param
    public_id
  end
end
