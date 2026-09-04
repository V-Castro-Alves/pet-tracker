class FoodBagsController < ApplicationController
  before_action :set_pet

  def index
    @active_bag = @pet.active_food_bag
    @food_bags = @pet.food_bags.recent_first
  end

  def new
    @food_bag = @pet.food_bags.new(started_at: Time.current, low_stock_percentage: 15)
  end

  def create
    @food_bag = FoodBags::Start.new(pet: @pet, attributes: food_bag_attributes).call
    redirect_to pet_food_bags_path(@pet), notice: "New food bag started."
  rescue ActiveRecord::RecordInvalid => error
    @food_bag = error.record
    render :new, status: :unprocessable_entity
  end

  def finish
    bag = @pet.food_bags.active.find(params[:id])
    bag.update!(ended_at: Time.current)
    redirect_to pet_food_bags_path(@pet), status: :see_other, notice: "Food bag marked as finished."
  end

  private
    def set_pet
      @pet = current_user_pet!
    end

    def food_bag_params
      params.expect(food_bag: %i[total_weight_g low_stock_percentage started_at])
    end

    def food_bag_attributes
      food_bag_params.to_h.symbolize_keys.tap do |attributes|
        attributes[:started_at] = Time.use_zone(@pet.time_zone) { Time.zone.parse(attributes[:started_at]) }
      end
    end
end
