module FoodBags
  class Start
    def initialize(pet:, attributes:)
      @pet = pet
      @attributes = attributes
    end

    def call
      pet.with_lock do
        pet.active_food_bag&.update!(ended_at: attributes[:started_at])
        pet.food_bags.create!(attributes.merge(remaining_weight_g: attributes[:total_weight_g]))
      end
    end

    private
      attr_reader :pet, :attributes
  end
end
