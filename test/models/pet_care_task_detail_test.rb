require "test_helper"

class PetCareTaskDetailTest < ActiveSupport::TestCase
  test "requires the pet and task to share a household" do
    task = households(:one).tasks.new(title: "Walk", kind: "pet_care", recurrence: "daily", starts_on: Date.current, local_time: "09:00", time_zone: "UTC")
    detail = task.build_pet_care_task_detail(pet: pets(:two), care_type: "walking")

    assert_not detail.valid?
    assert_includes detail.errors[:pet], "must belong to this household"
  end

  test "feeding amounts only apply to feeding tasks" do
    task = households(:one).tasks.new(title: "Walk", kind: "pet_care", recurrence: "daily", starts_on: Date.current, local_time: "09:00", time_zone: "UTC")
    detail = task.build_pet_care_task_detail(pet: pets(:one), care_type: "walking", amount_g: 50)

    assert_not detail.valid?
    assert_includes detail.errors[:amount_g], "is only available for feeding tasks"
  end
end
