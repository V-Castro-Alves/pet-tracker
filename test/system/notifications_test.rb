require "application_system_test_case"

class NotificationsTest < ApplicationSystemTestCase
  test "user sees and opens an unread notification" do
    sign_in_as users(:one)
    visit notifications_path

    assert_text notifications(:unread_food).title
    submit_form "Read and open"

    assert_current_path notifications(:unread_food).path
    assert notifications(:unread_food).reload.read?
  end
  test "caretaker changes their meal reminder" do
    sign_in_as users(:one)
    visit edit_pet_meal_slot_path(pets(:one), meal_slots(:breakfast))
    set_control "#reminder_preference_delay_minutes", "5"
    submit_form "Update Meal slot"
    assert_text "Breakfast was updated."
    visit edit_pet_meal_slot_path(pets(:one), meal_slots(:breakfast))
    assert_field "Grace window (minutes after meal time)", with: "5"
    select "No reminders for this meal", from: "Remind me if this meal has not been logged"
    submit_form "Update Meal slot"
    assert_text "Breakfast was updated."
    visit edit_pet_meal_slot_path(pets(:one), meal_slots(:breakfast))
    assert_select "Remind me if this meal has not been logged", selected: "No reminders for this meal"
  end
  test "unconfigured push hides both device buttons" do
    original_public = ENV.delete("VAPID_PUBLIC_KEY")
    original_private = ENV.delete("VAPID_PRIVATE_KEY")
    sign_in_as users(:one)
    visit notifications_path
    assert_text "Push notifications are not configured on this server."
    assert_no_button "Enable push"
    assert_no_button "Disable push"
  ensure
    ENV["VAPID_PUBLIC_KEY"] = original_public
    ENV["VAPID_PRIVATE_KEY"] = original_private
  end

  test "enable push saves the browser subscription and can disable it" do
    sign_in_as users(:one)
    visit notifications_path
    prepare_push_browser
    execute_script "arguments[0].click()", find_button("Enable push")
    assert_text "Push notifications are enabled on this device."
    assert_no_button "Enable push"
    assert_button "Disable push"
    execute_script "arguments[0].click()", find_button("Disable push")
    assert_text "Push notifications are not enabled on this device."
    assert_button "Enable push"
    assert_no_button "Disable push"
  end

  test "failed subscription save shows an error instead of success" do
    sign_in_as users(:one)
    visit notifications_path
    prepare_push_browser
    execute_script 'window.fetch = async () => new Response("", { status: 422 })'
    execute_script "arguments[0].click()", find_button("Enable push")
    assert_text "Could not save device settings."
    assert_no_text "Push notifications are enabled on this device."
    assert_button "Enable push", disabled: false
  end

  test "new notifications and badge arrive without a page refresh" do
    sign_in_as users(:one)
    visit notifications_path
    assert_selector "turbo-cable-stream-source[connected]", visible: :all
    before_count = users(:one).notifications.unread.count
    notification = Notification.create!(user: users(:one), kind: "meal_unresolved",
      title: "Dinner live update", body: "Dinner is waiting", path: "/notifications",
      deduplication_key: "system-live")

    assert_text "Dinner live update"
    assert_selector "#notification-badge", text: (before_count + 1).to_s
    notification.update!(read_at: Time.current)
    assert_selector "#notification-badge", text: before_count.to_s
    assert_selector ".notification-row:not(.notification-unread)", text: "Dinner live update"
  end

  private
    def prepare_push_browser
      assert_selector "[data-controller='push-notifications']"
      execute_script <<~JS
        const element = document.querySelector("[data-controller='push-notifications']")
        const controller = window.Stimulus.getControllerForElementAndIdentifier(element, "push-notifications")
        controller.publicKeyValue = "AQID"
        Object.defineProperty(Notification, "requestPermission", { configurable: true, value: async () => "granted" })
        const subscription = {
          endpoint: "https://push.example.test/system-device",
          toJSON() { return { endpoint: this.endpoint, keys: { p256dh: "key", auth: "auth" } } },
          unsubscribe: async () => true
        }
        controller.registration = { pushManager: { subscribe: async () => subscription } }
        controller.enableTarget.hidden = false
        controller.enableTarget.disabled = false
      JS
    end
end
