require "net/http"
require "resolv"
require "ipaddr"
require "openssl"
module Webhooks
  class Deliver
    BLOCKED = %w[0.0.0.0/8 10.0.0.0/8 100.64.0.0/10 127.0.0.0/8 169.254.0.0/16 172.16.0.0/12 192.0.0.0/24 192.0.2.0/24 192.168.0.0/16 198.18.0.0/15 198.51.100.0/24 203.0.113.0/24 224.0.0.0/4 240.0.0.0/4].map { |range| IPAddr.new(range) }.freeze
    def self.public_addresses(host, resolver: Resolv)
      addresses = resolver.getaddresses(host)
      raise ArgumentError, "Destination has no addresses" if addresses.empty?
      addresses.each do |address|
        ip = IPAddr.new(address)
        # Only public IPv4 destinations are supported initially; reject mixed DNS responses.
        raise ArgumentError, "Destination must resolve only to public IPv4 addresses" unless ip.ipv4? && BLOCKED.none? { |range| range.include?(ip) }
      end
      addresses
    end
    def self.call(delivery, http_class: Net::HTTP, resolver: Resolv)
      claimed = false
      delivery.with_lock do
        return if delivery.delivered_at || delivery.attempts >= 8 || (delivery.next_attempt_at && delivery.next_attempt_at > Time.current)
        endpoint = delivery.webhook_endpoint
        unless endpoint.active? && endpoint.household.administered_by?(endpoint.user) && delivery.domain_event.household_id == endpoint.household_id
          delivery.update!(attempts: 8, last_error: "Endpoint disabled or permission revoked")
          return
        end
        # Lease the attempt before network I/O, releasing SQLite's write lock promptly.
        delivery.update!(attempts: delivery.attempts + 1, next_attempt_at: 1.minute.from_now)
        claimed = true
      end
      return unless claimed
      endpoint = delivery.webhook_endpoint.reload
      begin
        raise ArgumentError, "Endpoint disabled or permission revoked" unless endpoint.active? && endpoint.household.administered_by?(endpoint.user)
        uri = URI.parse(endpoint.url)
        raise ArgumentError, "HTTPS port 443 required" unless uri.is_a?(URI::HTTPS) && uri.port == 443 && uri.userinfo.nil?
        address = public_addresses(uri.host, resolver: resolver).first
        event = delivery.domain_event
        body = { id: event.public_id, type: event.kind, occurred_at: event.created_at.iso8601, data: event.payload }.to_json
        timestamp = Time.current.to_i.to_s
        signature = OpenSSL::HMAC.hexdigest("SHA256", endpoint.secret, "#{timestamp}.#{body}")
        http = http_class.new(uri.host, 443, nil)
        http.ipaddr = address
        http.use_ssl = true
        http.open_timeout = 5
        http.read_timeout = 10
        http.write_timeout = 10
        request = Net::HTTP::Post.new(uri.request_uri, "Content-Type" => "application/json", "X-Webhook-Id" => event.public_id, "X-Webhook-Timestamp" => timestamp, "X-Webhook-Signature" => "v1=#{signature}")
        request.body = body
        # Do not download an unbounded response body from a user-configured endpoint.
        http.request(request) do |response|
          raise StandardError, "HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)
          response.read_body { |_chunk| break }
        end
        delivery.update!(delivered_at: Time.current, last_error: nil, next_attempt_at: nil)
      rescue StandardError => error
        delivery.update!(last_error: error.message.truncate(500), next_attempt_at: delivery.attempts < 8 ? Time.current + [ 2**delivery.attempts, 360 ].min.minutes : nil)
      end
    end
  end
end
