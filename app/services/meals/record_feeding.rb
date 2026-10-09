module Meals
  class RecordFeeding
    def self.call(pet:, actor:, amount:, credited_user: actor, occurrence: nil)
      pet.with_lock do
        raise ActiveRecord::RecordNotFound unless pet.household.users.exists?(id: actor.id) && pet.household.users.exists?(id: credited_user.id)
        entry = pet.feeding_entries.create!(actor: actor, credited_user: credited_user, amount_g: amount, fed_at: Time.current, task_occurrence: occurrence)
        bag = pet.active_food_bag
        if bag
          was_low = bag.low_stock?
          bag.update!(remaining_weight_g: bag.remaining_weight_g - entry.amount_g)
          if !was_low && bag.low_stock?
            Notifications::Publish.new(pet: pet, kind: "food_low", title: "#{pet.name}'s food is running low", body: "About #{bag.remaining_weight_g.round} g remains.", path: Rails.application.routes.url_helpers.pet_food_bags_path(pet), deduplication_key: "food_bag:#{bag.id}:low").call
            bag.update!(low_stock_notified_at: Time.current)
          end
        end
        entry
      end
    end
  end
end
