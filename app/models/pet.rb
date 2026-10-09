class Pet < ApplicationRecord
  belongs_to :household
  has_many :pet_care_task_details, dependent: :restrict_with_error
  has_many :tasks, through: :pet_care_task_details
  has_many :feeding_entries, dependent: :destroy
  has_secure_token :qr_token, length: 24
  before_validation :assign_public_id, on: :create

  has_one_attached :photo
  has_many :food_bags, dependent: :destroy
  has_many :weight_logs, dependent: :destroy
  has_many :vaccines, dependent: :destroy
  has_many :medical_entries, dependent: :destroy
  has_many :notifications, dependent: :destroy

  def users
    household.users
  end

  def active_food_bag
    food_bags.active.first
  end

  def administered_by?(user)
    household.administered_by?(user)
  end

  def average_daily_consumption_g(since: 30.days.ago)
    entries = feeding_entries.where(fed_at: since..).group_by { |entry| entry.fed_at.in_time_zone(time_zone).to_date }
    return 0.to_d if entries.empty?

    entries.values.sum { |daily| daily.sum(&:amount_g) } / entries.size
  end

  validates :name, :species, :public_id, presence: true
  validates :public_id, uniqueness: true
  validates :sex, inclusion: { in: %w[female male unknown] }, allow_blank: true
  validates :time_zone,
    presence: true,
    inclusion: { in: ActiveSupport::TimeZone.all.map(&:name), message: "is not a valid time zone" }
  validate :birthdate_cannot_be_in_the_future
  validate :acceptable_photo

  def to_param
    public_id
  end

  private
    def assign_public_id
      self.public_id ||= SecureRandom.uuid
    end

    def birthdate_cannot_be_in_the_future
      errors.add(:birthdate, "cannot be in the future") if birthdate.present? && birthdate > Date.current
    end

    def acceptable_photo
      return unless photo.attached?

      errors.add(:photo, "must be a JPEG, PNG, or WebP image") unless photo.content_type.in?(%w[image/jpeg image/png image/webp])
      errors.add(:photo, "must be smaller than 5 MB") if photo.byte_size > 5.megabytes
    end
end
