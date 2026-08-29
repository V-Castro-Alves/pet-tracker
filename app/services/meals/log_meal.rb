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

        bag.update!(remaining_weight_g: bag.remaining_weight_g - meal_log.actual_amount_g)
      end
  end
end
