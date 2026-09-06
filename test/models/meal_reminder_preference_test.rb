require "test_helper"

class MealReminderPreferenceTest < ActiveSupport::TestCase
  test "delay must be whole minutes between zero and one day" do
    preference = MealReminderPreference.new(meal_slot: meal_slots(:breakfast), user: users(:one))
    [ -1, 1441, 1.5, nil ].each do |delay|
      preference.delay_minutes = delay
      assert_not preference.valid?
    end
    [ 0, 5, 30, 1440 ].each do |delay|
      preference.delay_minutes = delay
      assert preference.valid?
    end
    preference.save!
    assert_not preference.dup.valid?
  end
end
