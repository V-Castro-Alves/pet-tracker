module Meals
  class LogMeal
    class DuplicateMealError < StandardError
      attr_reader :existing_log

      def initialize(existing_log)
        @existing_log = existing_log
        super("This meal has already been resolved")
      end
    end

    def initialize(pet:, meal_slot:, user:, attributes:, allow_duplicate: false)
      @pet = pet
      @meal_slot = meal_slot
      @user = user
      @attributes = attributes
      @allow_duplicate = allow_duplicate
    end

    def call
      pet.with_lock do
        existing = pet.meal_logs.find_by(meal_slot: meal_slot, scheduled_for: attributes[:scheduled_for])
        raise DuplicateMealError, existing if existing && !allow_duplicate

        meal_log = pet.meal_logs.create!(attributes.merge(
          meal_slot: meal_slot,
          logged_by_user: user,
          duplicate_of: existing
        ))

        consume_from_active_bag!(meal_log)
        meal_log
      end
    end

    private
      attr_reader :pet, :meal_slot, :user, :attributes, :allow_duplicate

      def consume_from_active_bag!(meal_log)
        return unless meal_log.fed?

        bag = pet.active_food_bag
        return unless bag

        was_low = bag.low_stock?
        bag.update!(remaining_weight_g: bag.remaining_weight_g - meal_log.actual_amount_g)
        publish_low_stock!(bag) if !was_low && bag.low_stock?
      end

      def publish_low_stock!(bag)
        Notifications::Publish.new(
          pet: pet,
          kind: "food_low",
          title: "#{pet.name}'s food is running low",
          body: "About #{bag.remaining_weight_g.round} g remains in the current bag.",
          path: Rails.application.routes.url_helpers.pet_food_bags_path(pet),
          deduplication_key: "food_bag:#{bag.id}:low"
        ).call
        bag.update!(low_stock_notified_at: Time.current)
      end
  end
end
