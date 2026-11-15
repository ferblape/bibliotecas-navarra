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

  test "searches the catalog" do
    Rails.cache.write([ "catalog", "search", "Patria", :title, "BPN/BP21", 1 ], Opac::ResultsPage.new(opac_fixture("results_san_pedro")).results)

    result = call_tool("search_catalog", query: " Patria ", field: "title", library: "BPN/BP21")

    assert_equal 2, result[:structuredContent][:total]
    assert_equal 1, result[:structuredContent][:page]
    assert_equal 1, result[:structuredContent][:total_pages]
    assert_equal({ id: "554980", title: "Patria", responsibility: "Fernando Aramburu.", author: "Aramburu, Fernando (1959- )",
                   publication: "Barcelona : Tusquets, 2016.", year: "2016", isbn: "978-84-9066-319-6", material: "Monografías",
                   url: "http://www.example.com/records/554980", opac_url: "https://www.navarra.es/opac/abnetcl.exe?TITN=554980" },
                 result[:structuredContent][:records].first)
  end

  test "searches only in the known fields" do
    result = call_tool("search_catalog", query: "Patria", field: "isbn")

    assert result[:isError]
    assert_match "Invalid arguments", result[:content].first[:text]
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
