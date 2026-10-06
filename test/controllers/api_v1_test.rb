require "test_helper"
class ApiV1Test < ActionDispatch::IntegrationTest
  setup do
    @household = Household.create!(name: "Home", time_zone: "UTC")
    @household.memberships.create!(user: users(:one), admin: true)
    @token, @raw = ApiToken.issue!(household: @household, user: users(:one), name: "Test", scopes: ApiToken::SCOPES, expires_at: 1.day.from_now)
    @headers = { "Authorization" => "Bearer #{@raw}", "Idempotency-Key" => "create-task" }
    @url = "/api/v1/households/#{@household.public_id}/tasks"
    @body = { task: { title: "Dishes", recurrence: "daily", starts_on: Date.current.iso8601, local_time: "09:00", time_zone: "UTC" } }
  end
  test "create retries replay and conflicting keys fail" do
    assert_difference "Task.count", 1 do
      2.times do
        post @url, params: @body, headers: @headers, as: :json
        assert_response :created
      end
    end
    post @url, params: @body.deep_merge(task: { title: "Trash" }), headers: @headers, as: :json
    assert_response :conflict
  end
  test "requires authentication scopes keys and household membership" do
    get @url, as: :json
    assert_response :unauthorized
    post @url, params: @body, headers: @headers.except("Idempotency-Key"), as: :json
    assert_response :bad_request
    @token.update!(scopes: [ "tasks:read" ])
    post @url, params: @body, headers: @headers, as: :json
    assert_response :forbidden
    other = Household.create!(name: "Other", time_zone: "UTC")
    get "/api/v1/households/#{other.public_id}/tasks", headers: @headers, as: :json
    assert_response :not_found
    @token.update!(revoked_at: Time.current)
    get @url, headers: @headers, as: :json
    assert_response :unauthorized
  end
  test "occurrence completion uses stable opaque identifiers" do
    post @url, params: @body, headers: @headers, as: :json
    assert_response :created
    task_id = response.parsed_body.dig("data", "id")
    get "/api/v1/households/#{@household.public_id}/occurrences", headers: @headers, as: :json
    assert_response :success
    occurrence = response.parsed_body.fetch("data").first
    assert_equal task_id, occurrence["task_id"]
    patch "/api/v1/households/#{@household.public_id}/occurrences/#{occurrence['id']}", params: { occurrence: { status: "completed" } }, headers: @headers.merge("Idempotency-Key" => "complete"), as: :json
    assert_response :success
    assert_equal "completed", response.parsed_body.dig("data", "status")
  end
  test "session API requires CSRF and removed members cannot replay responses" do
    ActionController::Base.allow_forgery_protection = true
    sign_in_as users(:one)
    post @url, params: @body, headers: { "Idempotency-Key" => "session-create" }, as: :json
    assert_response :unprocessable_entity
    assert_equal "invalid_csrf_token", response.parsed_body.dig("error", "code")
    get root_path
    csrf = Nokogiri::HTML(response.body).at_css('meta[name="csrf-token"]')["content"]
    headers = { "Idempotency-Key" => "session-create", "X-CSRF-Token" => csrf }
    post @url, params: @body, headers: headers, as: :json
    assert_response :created
    @household.memberships.delete_all
    post @url, params: @body, headers: headers, as: :json
    assert_response :not_found
  ensure
    ActionController::Base.allow_forgery_protection = false
  end
  test "members, reminders, update, and archive follow the contract" do
    get "/api/v1/households/#{@household.public_id}/members", headers: @headers, as: :json
    assert_response :success
    assert_equal users(:one).public_id, response.parsed_body.fetch("data").first.fetch("id")
    post @url, params: @body, headers: @headers, as: :json
    id = response.parsed_body.dig("data", "id")
    patch "#{@url}/#{id}/reminder", params: { reminder: { enabled: true, delay_minutes: 30, weekday_delays: { "0" => nil, "1" => 120 } } }, headers: @headers.merge("Idempotency-Key" => "reminder"), as: :json
    assert_response :success
    assert_equal({ "0" => nil, "1" => 120 }, response.parsed_body.dig("data", "weekday_delays"))
    occurrence_ids = Task.find_by!(public_id: id).task_occurrences.pluck(:public_id)
    patch "#{@url}/#{id}", params: { task: { title: "Clean dishes", assignee_id: users(:one).public_id } }, headers: @headers.merge("Idempotency-Key" => "assign"), as: :json
    assert_response :success
    assert_equal occurrence_ids, Task.find_by!(public_id: id).task_occurrences.pluck(:public_id)
    delete "#{@url}/#{id}", headers: @headers.merge("Idempotency-Key" => "archive"), as: :json
    assert_response :success
    assert response.parsed_body.dig("data", "archived_at")
  end
end
