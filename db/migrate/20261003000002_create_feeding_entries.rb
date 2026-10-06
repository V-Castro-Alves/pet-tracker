class CreateFeedingEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :feeding_entries do |t|
      t.references :pet, null: false, foreign_key: true
      t.references :task_occurrence, foreign_key: true, index: { unique: true }
      t.references :actor, null: false, foreign_key: { to_table: :users }
      t.references :credited_user, null: false, foreign_key: { to_table: :users }
      t.decimal :amount_g, null: false, precision: 8, scale: 2
      t.datetime :fed_at, null: false
      t.string :public_id, null: false, index: { unique: true }
      t.timestamps
      t.check_constraint "amount_g > 0", name: "feeding_entries_positive_amount"
    end
  end
end
