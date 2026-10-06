class Membership < ApplicationRecord
  belongs_to :household
  belongs_to :user
  validates :user_id, uniqueness: { scope: :household_id }
end
