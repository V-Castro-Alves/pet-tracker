# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_08_29_180000) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.integer "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.integer "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "food_bags", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "ended_at"
    t.datetime "low_stock_notified_at"
    t.decimal "low_stock_percentage", precision: 5, scale: 2, default: "15.0", null: false
    t.integer "pet_id", null: false
    t.decimal "remaining_weight_g", precision: 10, scale: 2, null: false
    t.datetime "started_at", null: false
    t.decimal "total_weight_g", precision: 10, scale: 2, null: false
    t.datetime "updated_at", null: false
    t.index ["pet_id"], name: "index_food_bags_on_one_active_per_pet", unique: true, where: "ended_at IS NULL"
    t.index ["pet_id"], name: "index_food_bags_on_pet_id"
    t.check_constraint "low_stock_percentage > 0 AND low_stock_percentage <= 100", name: "food_bags_valid_low_stock_percentage"
    t.check_constraint "total_weight_g > 0", name: "food_bags_positive_total"
  end

  create_table "meal_logs", force: :cascade do |t|
    t.decimal "actual_amount_g", precision: 8, scale: 2
    t.datetime "actual_time"
    t.datetime "created_at", null: false
    t.integer "duplicate_of_id"
    t.integer "logged_by_user_id", null: false
    t.integer "meal_slot_id", null: false
    t.integer "pet_id", null: false
    t.datetime "scheduled_for", null: false
    t.string "status", null: false
    t.datetime "updated_at", null: false
    t.index ["duplicate_of_id"], name: "index_meal_logs_on_duplicate_of_id"
    t.index ["logged_by_user_id"], name: "index_meal_logs_on_logged_by_user_id"
    t.index ["meal_slot_id", "scheduled_for"], name: "index_meal_logs_on_meal_slot_id_and_scheduled_for"
    t.index ["meal_slot_id"], name: "index_meal_logs_on_meal_slot_id"
    t.index ["pet_id"], name: "index_meal_logs_on_pet_id"
  end

  create_table "meal_slots", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.decimal "default_amount_g", precision: 8, scale: 2, null: false
    t.string "name", null: false
    t.integer "pet_id", null: false
    t.time "scheduled_time", null: false
    t.datetime "updated_at", null: false
    t.index ["pet_id", "scheduled_time"], name: "index_active_meal_slots_on_pet_and_time", unique: true, where: "active = 1"
    t.index ["pet_id"], name: "index_meal_slots_on_pet_id"
  end

  create_table "pet_users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "is_pet_admin", default: false, null: false
    t.datetime "linked_at", null: false
    t.integer "pet_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["pet_id", "user_id"], name: "index_pet_users_on_pet_id_and_user_id", unique: true
    t.index ["pet_id"], name: "index_pet_users_on_pet_id"
    t.index ["user_id"], name: "index_pet_users_on_user_id"
  end

  create_table "pets", force: :cascade do |t|
    t.date "birthdate"
    t.string "breed"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.text "notes"
    t.string "qr_token", null: false
    t.string "sex"
    t.string "species", null: false
    t.string "time_zone", default: "UTC", null: false
    t.datetime "updated_at", null: false
    t.index ["qr_token"], name: "index_pets_on_qr_token", unique: true
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "name", default: "", null: false
    t.string "password_digest", null: false
    t.string "time_zone", default: "UTC", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "food_bags", "pets"
  add_foreign_key "meal_logs", "meal_logs", column: "duplicate_of_id"
  add_foreign_key "meal_logs", "meal_slots"
  add_foreign_key "meal_logs", "pets"
  add_foreign_key "meal_logs", "users", column: "logged_by_user_id"
  add_foreign_key "meal_slots", "pets"
  add_foreign_key "pet_users", "pets"
  add_foreign_key "pet_users", "users"
  add_foreign_key "sessions", "users"
end
