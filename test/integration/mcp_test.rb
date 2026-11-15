require "test_helper"

class McpTest < ActionDispatch::IntegrationTest
  SAN_PEDRO = Opac::Library.new(code: "BPN/BP21", name: "Pamplona-San Pedro")

  setup do
    Rails.cache.write([ "catalog", "libraries" ], [ SAN_PEDRO ])
  end

  teardown do
    Rails.cache.clear
  end

  test "introduces itself and its read-only tools" do
    mcp_request("initialize", { protocolVersion: "2025-06-18", capabilities: {}, clientInfo: { name: "test", version: "1.0" } })
    assert_response :success
    assert_match "Bibliotecas Públicas de Navarra", response.parsed_body.dig("result", "instructions")

    mcp_request("tools/list")
    tools = response.parsed_body.dig("result", "tools")
    assert_equal %w[ list_libraries search_catalog get_record ], tools.map { it["name"] }
    assert tools.all? { it.dig("annotations", "readOnlyHint") }
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

  test "shows a record with its copies" do
    cache_record

    result = call_tool("get_record", id: "554980")

    assert_equal "Patria", result[:structuredContent][:title]
    assert_equal "http://www.example.com/records/554980", result[:structuredContent][:url]
    assert_equal 87, result[:structuredContent][:copies].size
    assert_equal({ library_code: "BB1", library_name: "Bibliobús 1 (Tierra Estella)", branch: "Bibliobús 1 - Tierra Estella",
                   location: "SALA DE PRESTAMO", status: "Prestable domicilio", call_number: "N ARA", format: "Libros",
                   availability: "Disponible", available: true },
                 result[:structuredContent][:copies].first)
  end

  test "shows the copies of a record in one library" do
    cache_record

    copies = call_tool("get_record", id: "554980", library: "BPN/BP21")[:structuredContent][:copies]

    assert_not_empty copies
    assert copies.all? { it[:library_name] == "Pamplona-San Pedro" }
  end

  test "tells the agent when a library does not exist" do
    cache_record

    result = call_tool("get_record", id: "554980", library: "BPN/XX99")

    assert result[:isError]
    assert_match "list_libraries", result[:content].first[:text]
  end

  test "tells the agent when the catalog is unavailable" do
    Rails.cache.clear
    result = with_opac_host("localhost") { call_tool("list_libraries") }

    assert result[:isError]
    assert_match "not available", result[:content].first[:text]
  end

  test "limits the requests of each agent" do
    10.times { mcp_request("tools/list") }
    assert_response :success

    mcp_request("tools/list")
    assert_too_many_requests

    mcp_request("tools/list", ip: "10.0.0.2")
    assert_response :success
  end

  test "limits the requests of all agents together to spare the OPAC" do
    6.times { |agent| 10.times { mcp_request("tools/list", ip: "10.0.0.#{agent + 1}") } }
    assert_response :success

    mcp_request("tools/list", ip: "10.0.0.7")
    assert_too_many_requests
  end

  private
    def assert_too_many_requests
      assert_response :too_many_requests
      assert_match "Too many requests", response.parsed_body.dig("error", "message")
    end

    def cache_record
      Rails.cache.write([ "catalog", "record", "554980" ], Opac::RecordPage.new(opac_fixture("record")).record)
    end

    def call_tool(name, arguments = {})
      mcp_request("tools/call", { name:, arguments: })
      assert_response :success
      response.parsed_body.deep_symbolize_keys.fetch(:result)
    end

    def mcp_request(method, params = {}, ip: "10.0.0.1")
      post mcp_path, params: { jsonrpc: "2.0", id: 1, method:, params: }.to_json, env: { "REMOTE_ADDR" => ip },
        headers: { "Content-Type" => "application/json", "Accept" => "application/json, text/event-stream" }
    end
end
