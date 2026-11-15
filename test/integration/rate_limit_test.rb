require "test_helper"

class RateLimitTest < ActionDispatch::IntegrationTest
  # Fly Proxy appends the app's own public IP to X-Forwarded-For and reaches the
  # machine from a private address, so every visitor arrives with the same tail.
  FLY_APP_IP = "66.241.125.10"
  FLY_PROXY_ADDR = "172.16.3.2"

  setup do
    Rails.cache.write([ "catalog", "libraries" ], [])
  end

  teardown do
    Rails.cache.clear
  end

  test "limits each visitor behind Fly Proxy on their own" do
    30.times { visit_from "203.0.113.7" }
    assert_response :success

    visit_from "203.0.113.7"
    assert_response :too_many_requests

    visit_from "198.51.100.23"
    assert_response :success
  end

  private
    def visit_from(client_ip)
      get root_path, headers: {
        "Fly-Client-IP" => client_ip,
        "X-Forwarded-For" => "#{client_ip}, #{FLY_APP_IP}"
      }, env: { "REMOTE_ADDR" => FLY_PROXY_ADDR }
    end
end
