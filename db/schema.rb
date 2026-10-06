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

ActiveRecord::Schema[8.1].define(version: 2026_10_03_000003) do
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

  create_table "api_requests", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "fingerprint", null: false
    t.string "key", null: false
    t.text "response_body"
    t.integer "response_status"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id", "key"], name: "index_api_requests_on_user_id_and_key", unique: true
    t.index ["user_id"], name: "index_api_requests_on_user_id"
  end

  create_table "api_tokens", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.integer "household_id", null: false
    t.string "name", null: false
    t.datetime "revoked_at"
    t.json "scopes", default: [], null: false
    t.string "token_digest", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["household_id"], name: "index_api_tokens_on_household_id"
    t.index ["token_digest"], name: "index_api_tokens_on_token_digest", unique: true
    t.index ["user_id"], name: "index_api_tokens_on_user_id"
  end

  create_table "domain_events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "deduplication_key", null: false
    t.integer "household_id", null: false
    t.string "kind", null: false
    t.json "payload", default: {}, null: false
    t.string "public_id", null: false
    t.datetime "updated_at", null: false
    t.index ["deduplication_key"], name: "index_domain_events_on_deduplication_key", unique: true
    t.index ["household_id"], name: "index_domain_events_on_household_id"
    t.index ["public_id"], name: "index_domain_events_on_public_id", unique: true
  end

  create_table "feeding_entries", force: :cascade do |t|
    t.integer "actor_id", null: false
    t.decimal "amount_g", precision: 8, scale: 2, null: false
    t.datetime "created_at", null: false
    t.integer "credited_user_id", null: false
    t.datetime "fed_at", null: false
    t.integer "pet_id", null: false
    t.string "public_id", null: false
    t.integer "task_occurrence_id"
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_feeding_entries_on_actor_id"
    t.index ["credited_user_id"], name: "index_feeding_entries_on_credited_user_id"
    t.index ["pet_id"], name: "index_feeding_entries_on_pet_id"
    t.index ["public_id"], name: "index_feeding_entries_on_public_id", unique: true
    t.index ["task_occurrence_id"], name: "index_feeding_entries_on_task_occurrence_id", unique: true
    t.check_constraint "amount_g > 0", name: "feeding_entries_positive_amount"
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

  create_table "household_invitations", force: :cascade do |t|
    t.datetime "accepted_at"
    t.datetime "created_at", null: false
    t.string "email"
    t.datetime "expires_at", null: false
    t.integer "household_id", null: false
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.index ["household_id"], name: "index_household_invitations_on_household_id"
    t.index ["token"], name: "index_household_invitations_on_token", unique: true
  end

  create_table "households", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.boolean "pets_enabled", default: false, null: false
    t.string "public_id", null: false
    t.string "time_zone", null: false
    t.datetime "updated_at", null: false
    t.index ["public_id"], name: "index_households_on_public_id", unique: true
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

  create_table "meal_reminder_preferences", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "delay_minutes", default: 60, null: false
    t.boolean "enabled", default: true, null: false
    t.integer "meal_slot_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.json "weekday_delays", default: {}, null: false
    t.index ["meal_slot_id", "user_id"], name: "index_meal_reminder_preferences_on_meal_slot_id_and_user_id", unique: true
    t.index ["meal_slot_id"], name: "index_meal_reminder_preferences_on_meal_slot_id"
    t.index ["user_id"], name: "index_meal_reminder_preferences_on_user_id"
    t.check_constraint "delay_minutes >= 0 AND delay_minutes <= 1440", name: "meal_reminder_delay_range"
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

  create_table "medical_entries", force: :cascade do |t|
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.integer "created_by_id", null: false
    t.date "entry_date", null: false
    t.integer "pet_id", null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_medical_entries_on_created_by_id"
    t.index ["pet_id", "entry_date"], name: "index_medical_entries_on_pet_id_and_entry_date"
    t.index ["pet_id"], name: "index_medical_entries_on_pet_id"
  end

  create_table "memberships", force: :cascade do |t|
    t.boolean "admin", default: false, null: false
    t.datetime "created_at", null: false
    t.integer "household_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["household_id", "user_id"], name: "index_memberships_on_household_id_and_user_id", unique: true
    t.index ["household_id"], name: "index_memberships_on_household_id"
    t.index ["user_id"], name: "index_memberships_on_user_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.string "deduplication_key", null: false
    t.datetime "delivered_at"
    t.string "kind", null: false
    t.string "path", default: "/", null: false
    t.integer "pet_id"
    t.datetime "read_at"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["pet_id"], name: "index_notifications_on_pet_id"
    t.index ["user_id", "deduplication_key"], name: "index_notifications_on_user_and_deduplication_key", unique: true
    t.index ["user_id", "read_at", "created_at"], name: "index_notifications_on_user_id_and_read_at_and_created_at"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "pet_invites", force: :cascade do |t|
    t.datetime "accepted_at"
    t.integer "accepted_by_id"
    t.datetime "created_at", null: false
    t.integer "created_by_id", null: false
    t.datetime "expires_at", null: false
    t.string "invite_token", null: false
    t.string "invited_email"
    t.integer "pet_id", null: false
    t.datetime "updated_at", null: false
    t.index ["accepted_by_id"], name: "index_pet_invites_on_accepted_by_id"
    t.index ["created_by_id"], name: "index_pet_invites_on_created_by_id"
    t.index ["invite_token"], name: "index_pet_invites_on_invite_token", unique: true
    t.index ["pet_id", "expires_at"], name: "index_pet_invites_on_pet_id_and_expires_at"
    t.index ["pet_id"], name: "index_pet_invites_on_pet_id"
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
    t.integer "household_id"
    t.string "name", null: false
    t.text "notes"
    t.string "public_id", null: false
    t.string "qr_token", null: false
    t.string "sex"
    t.string "species", null: false
    t.string "time_zone", default: "UTC", null: false
    t.datetime "updated_at", null: false
    t.index ["household_id"], name: "index_pets_on_household_id"
    t.index ["public_id"], name: "index_pets_on_public_id", unique: true
    t.index ["qr_token"], name: "index_pets_on_qr_token", unique: true
  end

  create_table "push_subscriptions", force: :cascade do |t|
    t.string "auth", null: false
    t.datetime "created_at", null: false
    t.text "endpoint", null: false
    t.string "p256dh", null: false
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["endpoint"], name: "index_push_subscriptions_on_endpoint", unique: true
    t.index ["user_id"], name: "index_push_subscriptions_on_user_id"
  end

  create_table "scheduler_heartbeats", force: :cascade do |t|
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.string "last_error"
    t.string "name", null: false
    t.datetime "started_at"
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_scheduler_heartbeats_on_name", unique: true
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "task_occurrences", force: :cascade do |t|
    t.integer "actor_id"
    t.decimal "actual_amount_g", precision: 8, scale: 2
    t.integer "assignee_id"
    t.datetime "created_at", null: false
    t.integer "credited_user_id"
    t.date "local_date", null: false
    t.string "public_id", null: false
    t.datetime "resolved_at"
    t.datetime "scheduled_at", null: false
    t.string "status", default: "pending", null: false
    t.integer "task_id", null: false
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_task_occurrences_on_actor_id"
    t.index ["assignee_id"], name: "index_task_occurrences_on_assignee_id"
    t.index ["credited_user_id"], name: "index_task_occurrences_on_credited_user_id"
    t.index ["public_id"], name: "index_task_occurrences_on_public_id", unique: true
    t.index ["task_id", "local_date"], name: "index_task_occurrences_on_task_id_and_local_date", unique: true
    t.index ["task_id"], name: "index_task_occurrences_on_task_id"
    t.check_constraint "status IN ('pending', 'completed', 'skipped')", name: "task_occurrences_valid_status"
  end

  create_table "task_reminder_preferences", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "delay_minutes", default: 60, null: false
    t.boolean "enabled", default: true, null: false
    t.integer "task_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.json "weekday_delays", default: {}, null: false
    t.index ["task_id", "user_id"], name: "index_task_reminder_preferences_on_task_id_and_user_id", unique: true
    t.index ["task_id"], name: "index_task_reminder_preferences_on_task_id"
    t.index ["user_id"], name: "index_task_reminder_preferences_on_user_id"
    t.check_constraint "delay_minutes >= 0 AND delay_minutes <= 1440", name: "task_reminder_delay_range"
  end

  create_table "tasks", force: :cascade do |t|
    t.datetime "archived_at"
    t.integer "assignee_id"
    t.string "category"
    t.datetime "created_at", null: false
    t.decimal "feeding_amount_g", precision: 8, scale: 2
    t.integer "household_id", null: false
    t.string "local_time", null: false
    t.text "notes"
    t.integer "pet_id"
    t.string "public_id", null: false
    t.string "recurrence", default: "daily", null: false
    t.date "starts_on", null: false
    t.string "time_zone", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.json "weekdays", default: [], null: false
    t.index ["assignee_id"], name: "index_tasks_on_assignee_id"
    t.index ["household_id"], name: "index_tasks_on_household_id"
    t.index ["pet_id"], name: "index_tasks_on_pet_id"
    t.index ["public_id"], name: "index_tasks_on_public_id", unique: true
    t.check_constraint "recurrence IN ('once', 'daily', 'weekly')", name: "tasks_valid_recurrence"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "name", default: "", null: false
    t.string "password_digest", null: false
    t.string "public_id", null: false
    t.string "time_zone", default: "UTC", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["public_id"], name: "index_users_on_public_id", unique: true
  end

  create_table "vaccines", force: :cascade do |t|
    t.string "clinic"
    t.datetime "created_at", null: false
    t.date "date_given", null: false
    t.string "name", null: false
    t.date "next_due_date"
    t.text "notes"
    t.integer "pet_id", null: false
    t.datetime "updated_at", null: false
    t.index ["pet_id", "next_due_date"], name: "index_vaccines_on_pet_id_and_next_due_date"
    t.index ["pet_id"], name: "index_vaccines_on_pet_id"
  end

  create_table "webhook_deliveries", force: :cascade do |t|
    t.integer "attempts", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "delivered_at"
    t.integer "domain_event_id", null: false
    t.text "last_error"
    t.datetime "next_attempt_at"
    t.datetime "updated_at", null: false
    t.integer "webhook_endpoint_id", null: false
    t.index ["domain_event_id", "webhook_endpoint_id"], name: "idx_on_domain_event_id_webhook_endpoint_id_a7b3c3029e", unique: true
    t.index ["domain_event_id"], name: "index_webhook_deliveries_on_domain_event_id"
    t.index ["webhook_endpoint_id"], name: "index_webhook_deliveries_on_webhook_endpoint_id"
  end

  create_table "webhook_endpoints", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.integer "household_id", null: false
    t.string "secret", null: false
    t.datetime "updated_at", null: false
    t.string "url", null: false
    t.integer "user_id", null: false
    t.index ["household_id"], name: "index_webhook_endpoints_on_household_id"
    t.index ["user_id"], name: "index_webhook_endpoints_on_user_id"
  end

  create_table "weight_logs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "logged_at", null: false
    t.text "note"
    t.integer "pet_id", null: false
    t.datetime "updated_at", null: false
    t.decimal "weight_kg", precision: 7, scale: 2, null: false
    t.index ["pet_id", "logged_at"], name: "index_weight_logs_on_pet_id_and_logged_at", unique: true
    t.index ["pet_id"], name: "index_weight_logs_on_pet_id"
    t.check_constraint "weight_kg > 0", name: "weight_logs_positive_weight"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "api_requests", "users"
  add_foreign_key "api_tokens", "households"
  add_foreign_key "api_tokens", "users"
  add_foreign_key "domain_events", "households"
  add_foreign_key "feeding_entries", "pets"
  add_foreign_key "feeding_entries", "task_occurrences"
  add_foreign_key "feeding_entries", "users", column: "actor_id"
  add_foreign_key "feeding_entries", "users", column: "credited_user_id"
  add_foreign_key "food_bags", "pets"
  add_foreign_key "household_invitations", "households"
  add_foreign_key "meal_logs", "meal_logs", column: "duplicate_of_id"
  add_foreign_key "meal_logs", "meal_slots"
  add_foreign_key "meal_logs", "pets"
  add_foreign_key "meal_logs", "users", column: "logged_by_user_id"
  add_foreign_key "meal_reminder_preferences", "meal_slots"
  add_foreign_key "meal_reminder_preferences", "users"
  add_foreign_key "meal_slots", "pets"
  add_foreign_key "medical_entries", "pets"
  add_foreign_key "medical_entries", "users", column: "created_by_id"
  add_foreign_key "memberships", "households"
  add_foreign_key "memberships", "users"
  add_foreign_key "notifications", "pets"
  add_foreign_key "notifications", "users"
  add_foreign_key "pet_invites", "pets"
  add_foreign_key "pet_invites", "users", column: "accepted_by_id"
  add_foreign_key "pet_invites", "users", column: "created_by_id"
  add_foreign_key "pet_users", "pets"
  add_foreign_key "pet_users", "users"
  add_foreign_key "pets", "households"
  add_foreign_key "push_subscriptions", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "task_occurrences", "tasks"
  add_foreign_key "task_occurrences", "users", column: "actor_id"
  add_foreign_key "task_occurrences", "users", column: "assignee_id"
  add_foreign_key "task_occurrences", "users", column: "credited_user_id"
  add_foreign_key "task_reminder_preferences", "tasks"
  add_foreign_key "task_reminder_preferences", "users"
  add_foreign_key "tasks", "households"
  add_foreign_key "tasks", "pets"
  add_foreign_key "tasks", "users", column: "assignee_id"
  add_foreign_key "vaccines", "pets"
  add_foreign_key "webhook_deliveries", "domain_events"
  add_foreign_key "webhook_deliveries", "webhook_endpoints"
  add_foreign_key "webhook_endpoints", "households"
  add_foreign_key "webhook_endpoints", "users"
  add_foreign_key "weight_logs", "pets"
end
