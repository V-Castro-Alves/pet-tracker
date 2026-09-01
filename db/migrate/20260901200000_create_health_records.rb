class CreateHealthRecords < ActiveRecord::Migration[8.1]
  def change
    create_table :weight_logs do |t|
      t.references :pet, null: false, foreign_key: true
      t.decimal :weight_kg, precision: 7, scale: 2, null: false
      t.date :logged_at, null: false
      t.text :note

      t.timestamps
    end
    add_index :weight_logs, %i[pet_id logged_at], unique: true
    add_check_constraint :weight_logs, "weight_kg > 0", name: :weight_logs_positive_weight

    create_table :vaccines do |t|
      t.references :pet, null: false, foreign_key: true
      t.string :name, null: false
      t.date :date_given, null: false
      t.date :next_due_date
      t.string :clinic
      t.text :notes

      t.timestamps
    end
    add_index :vaccines, %i[pet_id next_due_date]

    create_table :medical_entries do |t|
      t.references :pet, null: false, foreign_key: true
      t.date :entry_date, null: false
      t.string :title
      t.text :body, null: false
      t.references :created_by, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end
    add_index :medical_entries, %i[pet_id entry_date]
  end
end
