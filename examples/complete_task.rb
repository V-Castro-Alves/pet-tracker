#!/usr/bin/env ruby
require "net/http"
require "json"
require "securerandom"

base = ENV.fetch("BASE_URL")
raise "BASE_URL must use HTTPS" unless URI(base).is_a?(URI::HTTPS)
token = ENV.fetch("API_TOKEN")
household = ENV.fetch("HOUSEHOLD_ID")
request_api = lambda do |path, body = nil|
  uri = URI.join(base.end_with?("/") ? base : "#{base}/", path.delete_prefix("/"))
  request = body ? Net::HTTP::Patch.new(uri) : Net::HTTP::Get.new(uri)
  request["Authorization"] = "Bearer #{token}"
  if body
    request["Content-Type"] = "application/json"
    request["Idempotency-Key"] = ENV.fetch("ACTION_UUID") { SecureRandom.uuid }
    request.body = JSON.generate(body)
  end
  response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 5, read_timeout: 15) { |http| http.request(request) }
  raise "API returned #{response.code}: #{response.body}" unless response.is_a?(Net::HTTPSuccess)
  JSON.parse(response.body)
end
path = "/api/v1/households/#{URI.encode_www_form_component(household)}/occurrences"
page = 1
loop do
  entries = request_api.call("#{path}?status=pending&page=#{page}").fetch("data")
  break if entries.empty?
  entries.each { |entry| puts "#{entry.fetch('id')}  #{entry.fetch('scheduled_at')}  #{entry.fetch('title')}" }
  page += 1
end
if ENV["OCCURRENCE_ID"]
  result = request_api.call("#{path}/#{URI.encode_www_form_component(ENV.fetch('OCCURRENCE_ID'))}", { occurrence: { status: "completed" } })
  puts "Completed #{result.fetch('data').fetch('title')}"
end
