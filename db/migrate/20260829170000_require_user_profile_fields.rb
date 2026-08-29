class RequireUserProfileFields < ActiveRecord::Migration[8.1]
  def change
    change_column_default :users, :name, from: nil, to: ""
    change_column_default :users, :time_zone, from: nil, to: "UTC"
    change_column_null :users, :name, false, ""
    change_column_null :users, :time_zone, false, "UTC"
  end
end
