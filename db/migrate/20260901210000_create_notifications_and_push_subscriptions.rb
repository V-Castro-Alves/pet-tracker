class CreateNotificationsAndPushSubscriptions < ActiveRecord::Migration[8.1]
  def change
    create_table :notifications do |t|
      t.references :user, null: false, foreign_key: true
      t.references :pet, foreign_key: true
      t.string :kind, null: false
      t.string :title, null: false
      t.text :body, null: false
      t.string :path, null: false, default: "/"
      t.string :deduplication_key, null: false
      t.datetime :read_at
      t.datetime :delivered_at

      t.timestamps
    end
    add_index :notifications, %i[user_id deduplication_key], unique: true, name: :index_notifications_on_user_and_deduplication_key
    add_index :notifications, %i[user_id read_at created_at]

    create_table :push_subscriptions do |t|
      t.references :user, null: false, foreign_key: true
      t.text :endpoint, null: false
      t.string :p256dh, null: false
      t.string :auth, null: false
      t.string :user_agent

      t.timestamps
    end
    add_index :push_subscriptions, :endpoint, unique: true
  end
end
