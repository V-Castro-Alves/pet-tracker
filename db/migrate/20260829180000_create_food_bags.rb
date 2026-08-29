class CreateFoodBags < ActiveRecord::Migration[8.1]
  def change
    create_table :food_bags do |t|
      t.references :pet, null: false, foreign_key: true
      t.decimal :total_weight_g, precision: 10, scale: 2, null: false
      t.decimal :remaining_weight_g, precision: 10, scale: 2, null: false
      t.decimal :low_stock_percentage, precision: 5, scale: 2, null: false, default: 15
      t.datetime :started_at, null: false
      t.datetime :ended_at
      t.datetime :low_stock_notified_at

      t.timestamps
    end

    add_index :food_bags, :pet_id, unique: true, where: "ended_at IS NULL", name: :index_food_bags_on_one_active_per_pet
    add_check_constraint :food_bags, "total_weight_g > 0", name: :food_bags_positive_total
    add_check_constraint :food_bags, "low_stock_percentage > 0 AND low_stock_percentage <= 100", name: :food_bags_valid_low_stock_percentage
  end
end
