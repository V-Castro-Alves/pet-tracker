require "test_helper"
class HouseholdSecurityTest < ActiveSupport::TestCase
  setup do
    @household = Household.create!(name: "Home", time_zone: "UTC", pets_enabled: true)
    @household.memberships.create!(user: users(:one), admin: true)
  end
  test "feeding resolves once and consumes stock atomically" do
    pet = pets(:one)
    pet.update!(household: @household)
    task = Tasks::Save.call(task: @household.tasks.new, attributes: { title: "Breakfast", pet: pet, feeding_amount_g: 100, recurrence: "once", starts_on: Date.current, local_time: "09:00", time_zone: "UTC" })
    occurrence = task.task_occurrences.first
    bag = pet.active_food_bag
    before = bag.remaining_weight_g
    Tasks::Resolve.call(occurrence: occurrence, actor: users(:one), status: "completed")
    assert_equal before - 100, bag.reload.remaining_weight_g
    assert_equal 1, pet.feeding_entries.count
    assert_raises(Tasks::Resolve::Conflict) { Tasks::Resolve.call(occurrence: occurrence, actor: users(:one), status: "completed") }
    assert_equal before - 100, bag.reload.remaining_weight_g
  end
  test "cross-household assignments and pets are rejected" do
    task = @household.tasks.new(title: "Task", recurrence: "daily", starts_on: Date.current, local_time: "09:00", time_zone: "UTC", assignee: users(:two), pet: pets(:two), feeding_amount_g: 10)
    assert_not task.valid?
    assert task.errors[:assignee].any?
    assert task.errors[:pet].any?
  end
  test "expired and removed-member tokens are invalid" do
    token, raw = ApiToken.issue!(household: @household, user: users(:one), name: "Test", scopes: [ "tasks:read" ], expires_at: 1.second.ago)
    assert_nil ApiToken.authenticate(raw)
    token.update!(expires_at: 1.day.from_now)
    assert ApiToken.authenticate(raw)
    @household.memberships.delete_all
    assert_nil ApiToken.authenticate(raw)
  end
  test "webhook rejects local destinations and invalid schemes" do
    assert_raises(ArgumentError) { Webhooks::Deliver.public_addresses("127.0.0.1") }
    assert_raises(ArgumentError) { Webhooks::Deliver.public_addresses("169.254.169.254") }
    assert_raises(ArgumentError) { Webhooks::Deliver.public_addresses("::1") }
    endpoint = @household.webhook_endpoints.new(user: users(:one), url: "http://example.com")
    assert_not endpoint.valid?
  end
  test "disabled webhooks are terminal without network access" do
    endpoint = @household.webhook_endpoints.create!(user: users(:one), url: "https://example.com/hook", active: false)
    event = DomainEvent.publish!(household: @household, kind: "task.created", resource: @household)
    delivery = event.webhook_deliveries.create!(webhook_endpoint: endpoint)
    Webhooks::Deliver.call(delivery)
    assert_equal 8, delivery.reload.attempts
    assert_nil delivery.delivered_at
  end
  test "webhook failures persist retry diagnostics" do
    endpoint = @household.webhook_endpoints.create!(user: users(:one), url: "https://127.0.0.1/hook")
    event = DomainEvent.publish!(household: @household, kind: "task.created", resource: @household)
    delivery = event.webhook_deliveries.create!(webhook_endpoint: endpoint)
    Webhooks::Deliver.call(delivery)
    assert_equal 1, delivery.reload.attempts
    assert delivery.next_attempt_at > Time.current
    assert_match "public IPv4", delivery.last_error
  end
  test "webhooks sign raw body, pin public address, and deliver only once" do
    endpoint = @household.webhook_endpoints.create!(user: users(:one), url: "https://example.com/hook")
    event = DomainEvent.publish!(household: @household, kind: "task.created", resource: @household)
    delivery = event.webhook_deliveries.create!(webhook_endpoint: endpoint)
    client = Struct.new(:ipaddr, :use_ssl, :open_timeout, :read_timeout, :write_timeout, :sent_request) do
      def request(request)
        self.sent_request = request
        response = Net::HTTPOK.new("1.1", "200", "OK")
        response.define_singleton_method(:read_body) { |&block| block.call("ok") }
        yield response
      end
    end.new
    factory = Object.new
    factory.define_singleton_method(:new) { |*_args| client }
    resolver = Object.new
    resolver.define_singleton_method(:getaddresses) { |_host| [ "93.184.216.34" ] }
    Webhooks::Deliver.call(delivery, http_class: factory, resolver: resolver)
    assert delivery.reload.delivered_at
    assert_equal "93.184.216.34", client.ipaddr
    assert client.use_ssl
    request = client.sent_request
    expected = OpenSSL::HMAC.hexdigest("SHA256", endpoint.secret, "#{request['X-Webhook-Timestamp']}.#{request.body}")
    assert_equal "v1=#{expected}", request["X-Webhook-Signature"]
    assert_equal event.public_id, JSON.parse(request.body)["id"]
    Webhooks::Deliver.call(delivery, http_class: factory, resolver: resolver)
    assert_equal 1, delivery.reload.attempts
  end
  test "mixed public and private DNS is rejected" do
    resolver = Object.new
    resolver.define_singleton_method(:getaddresses) { |_host| [ "93.184.216.34", "10.0.0.1" ] }
    assert_raises(ArgumentError) { Webhooks::Deliver.public_addresses("example.com", resolver: resolver) }
  end
end
