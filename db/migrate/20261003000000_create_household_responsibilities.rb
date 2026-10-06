class CreateHouseholdResponsibilities < ActiveRecord::Migration[8.1]
  def change
    create_table :households do |t|
      t.string :public_id, null: false, index: { unique: true }
      t.string :name, null: false
      t.string :time_zone, null: false
      t.boolean :pets_enabled, default: false, null: false
      t.timestamps
    end
    create_table :memberships do |t|
      t.references :household, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.boolean :admin, default: false, null: false
      t.timestamps
      t.index [ :household_id, :user_id ], unique: true
    end
    create_table :household_invitations do |t|
      t.references :household, null: false, foreign_key: true
      t.string :token, null: false, index: { unique: true }
      t.string :email
      t.datetime :expires_at, null: false
      t.datetime :accepted_at
      t.timestamps
    end
    add_reference :pets, :household, foreign_key: true
    create_table :tasks do |t|
      t.references :household, null: false, foreign_key: true
      t.references :pet, foreign_key: true
      t.references :assignee, foreign_key: { to_table: :users }
      t.string :public_id, null: false, index: { unique: true }
      t.string :title, null: false
      t.text :notes
      t.string :category
      t.string :time_zone, null: false
      t.string :recurrence, null: false, default: 'daily'
      t.date :starts_on, null: false
      t.string :local_time, null: false
      t.json :weekdays, default: [], null: false
      t.decimal :feeding_amount_g, precision: 8, scale: 2
      t.datetime :archived_at
      t.timestamps
    end
    create_table :task_occurrences do |t|
      t.references :task, null: false, foreign_key: true
      t.references :assignee, foreign_key: { to_table: :users }
      t.references :actor, foreign_key: { to_table: :users }
      t.references :credited_user, foreign_key: { to_table: :users }
      t.string :public_id, null: false, index: { unique: true }
      t.date :local_date, null: false
      t.datetime :scheduled_at, null: false
      t.string :status, null: false, default: 'pending'
      t.datetime :resolved_at
      t.decimal :actual_amount_g, precision: 8, scale: 2
      t.timestamps
      t.index [ :task_id, :local_date ], unique: true
    end
    create_table :task_reminder_preferences do |t|
      t.references :task, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.boolean :enabled, null: false, default: true
      t.integer :delay_minutes, null: false, default: 60
      t.json :weekday_delays, null: false, default: {}
      t.timestamps
      t.index [ :task_id, :user_id ], unique: true
    end
    create_table :api_tokens do |t|
      t.references :household, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :token_digest, null: false, index: { unique: true }
      t.json :scopes, null: false, default: []
      t.datetime :expires_at, null: false
      t.datetime :revoked_at
      t.timestamps
    end
    create_table :api_requests do |t|
      t.references :user, null: false, foreign_key: true
      t.string :key, null: false
      t.string :fingerprint, null: false
      t.integer :response_status
      t.text :response_body
      t.timestamps
      t.index [ :user_id, :key ], unique: true
    end
    create_table :domain_events do |t|
      t.references :household, null: false, foreign_key: true
      t.string :public_id, null: false, index: { unique: true }
      t.string :kind, null: false
      t.string :deduplication_key, null: false, index: { unique: true }
      t.json :payload, null: false, default: {}
      t.timestamps
    end
    create_table :webhook_endpoints do |t|
      t.references :household, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :url, null: false
      t.string :secret, null: false
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    create_table :webhook_deliveries do |t|
      t.references :domain_event, null: false, foreign_key: true
      t.references :webhook_endpoint, null: false, foreign_key: true
      t.integer :attempts, null: false, default: 0
      t.datetime :delivered_at
      t.datetime :next_attempt_at
      t.text :last_error
      t.timestamps
      t.index [ :domain_event_id, :webhook_endpoint_id ], unique: true
    end
  end
end
