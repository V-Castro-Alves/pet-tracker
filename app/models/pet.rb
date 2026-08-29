class Pet < ApplicationRecord
  has_secure_token :qr_token, length: 24

  has_one_attached :photo
  has_many :pet_users, dependent: :destroy
  has_many :users, through: :pet_users
  has_many :meal_slots, dependent: :destroy
  has_many :meal_logs, dependent: :destroy

  validates :name, :species, presence: true
  validates :sex, inclusion: { in: %w[female male unknown] }, allow_blank: true
  validates :time_zone,
    presence: true,
    inclusion: { in: ActiveSupport::TimeZone.all.map(&:name), message: "is not a valid time zone" }
  validate :birthdate_cannot_be_in_the_future
  validate :acceptable_photo

  private
    def birthdate_cannot_be_in_the_future
      errors.add(:birthdate, "cannot be in the future") if birthdate.present? && birthdate > Date.current
    end

    def acceptable_photo
      return unless photo.attached?

      errors.add(:photo, "must be a JPEG, PNG, or WebP image") unless photo.content_type.in?(%w[image/jpeg image/png image/webp])
      errors.add(:photo, "must be smaller than 5 MB") if photo.byte_size > 5.megabytes
    end
end
