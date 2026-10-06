require "test_helper"

class OpenapiContractTest < ActiveSupport::TestCase
  test "every versioned API route has a documented operation" do
    contract = JSON.parse(Rails.root.join("public/openapi.json").read)
    routes = Rails.application.routes.routes.select { |route| route.defaults[:controller].to_s.start_with?("api/v1/") }
    routes.each do |route|
      path = route.path.spec.to_s.delete_suffix("(.:format)").gsub(/:([a-z_]+)/, '{\1}')
      route.verb.split("|").each do |verb|
        assert contract.fetch("paths").dig(path, verb.downcase), "Missing OpenAPI operation: #{verb} #{path}"
      end
    end
  end
end
