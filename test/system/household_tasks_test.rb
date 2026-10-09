require "application_system_test_case"
class HouseholdTasksTest < ApplicationSystemTestCase
  setup do
    ActionController::Base.allow_forgery_protection = true
    @household = Household.create!(name: "Our household", time_zone: "UTC")
    @household.memberships.create!(user: users(:one), admin: true)
    @household.household_modules.create!(key: "pet_care", enabled_by: users(:one), enabled_at: Time.current)
    @household.memberships.create!(user: users(:two))
    @task = Tasks::Save.call(task: @household.tasks.new, attributes: { title: "Wash the dishes", recurrence: "once", starts_on: Date.current, local_time: "09:00", time_zone: "UTC", assignee: users(:two) })
  end
  teardown do
    ActionController::Base.allow_forgery_protection = false
  end
  test "member completes shared responsibility through session-authenticated API" do
    sign_in_as users(:one)
    visit root_path
    assert_text "Wash the dishes"
    click_button "Complete", match: :first
    assert_text "Wash the dishes — completed by Alex"
    assert_no_button "Complete"
    click_button "Sign out"
    sign_in_as users(:two)
    visit root_path
    assert_text "Wash the dishes — completed by Alex"
  end
  test "assignment and personal reminders use the API" do
    sign_in_as users(:one)
    visit household_tasks_path(@household)
    assert_selector '[data-task-action-ready="true"]'
    select "Alex", from: "Responsible person"
    assert_text "Saved"
    visit household_tasks_path(@household)
    assert_selector "option:checked", text: "Alex"
    assert_selector '[data-task-action-ready="true"]'
    assert_checked_field "Remind me"
    uncheck "Remind me"
    assert_text "Saved"
    visit household_tasks_path(@household)
    assert_unchecked_field "Remind me"
  end
  test "task forms and tokens work" do
    sign_in_as users(:one)
    visit new_household_task_path(@household)
    set_control "#task_title", "Take out trash"
    submit_form "Create Task"
    assert_text "Take out trash"
    visit household_integrations_path(@household)
    set_control "#name", "My automation"
    check "scope_tasks_read"
    assert_checked_field "scope_tasks_read"
    submit_form "Create token"
    assert_text "Copy this token now"
    assert_text "My automation"
    visit household_integrations_path(@household)
    assert_no_text "Copy this token now"
  end
  test "pet creation retains household and feeding history" do
    sign_in_as users(:one)
    visit new_pet_path(household_id: @household.public_id)
    set_control "#pet_name", "Buddy"
    set_control "#pet_species", "Dog"
    submit_form "Create Pet"
    assert_text "Buddy was added to Pet Care."
    visit household_path(@household)
    click_link "Buddy"
    click_link "Feeding history"
    assert_text "Buddy's feedings"
  end
  test "household screens fit mobile and desktop viewports" do
    sign_in_as users(:one)
    [ 320, 390, 768, 1280 ].each do |width|
      page.current_window.resize_to(width, 900)
      [ root_path, new_household_task_path(@household), household_integrations_path(@household) ].each do |path|
        visit path
        assert_operator page.evaluate_script("document.documentElement.scrollWidth"), :<=, page.evaluate_script("window.innerWidth")
        assert_selector "main#main-content"
      end
      save_screenshot(Rails.root.join("tmp/screenshots/household-#{width}.png"))
    end
  end
end
