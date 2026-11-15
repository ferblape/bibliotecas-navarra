require "test_helper"

class McpTest < ActionDispatch::IntegrationTest
  SAN_PEDRO = Opac::Library.new(code: "BPN/BP21", name: "Pamplona-San Pedro")

  setup do
    Rails.cache.write([ "catalog", "libraries" ], [ SAN_PEDRO ])
  end

  teardown do
    Rails.cache.clear
  end

  test "lists the libraries" do
    result = call_tool("list_libraries")

    assert_equal({ libraries: [ { code: "BPN/BP21", name: "Pamplona-San Pedro" } ] }, result[:structuredContent])
  end

  test "tells the agent when the catalog is unavailable" do
    Rails.cache.clear
    result = with_opac_host("localhost") { call_tool("list_libraries") }

    assert result[:isError]
    assert_match "not available", result[:content].first[:text]
  end

  private
    def call_tool(name, arguments = {})
      mcp_request("tools/call", name:, arguments:)
      assert_response :success
      response.parsed_body.deep_symbolize_keys.fetch(:result)
    end

    def mcp_request(method, params = {})
      post mcp_path, params: { jsonrpc: "2.0", id: 1, method:, params: }.to_json,
        headers: { "Content-Type" => "application/json", "Accept" => "application/json, text/event-stream" }
    end
end
