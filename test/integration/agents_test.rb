require "test_helper"

class AgentsTest < ActionDispatch::IntegrationTest
  test "explains to people how to connect an agent" do
    get agents_path

    assert_response :success
    assert_select "h1", /agentes/i
    assert_select "code", mcp_url
    assert_select "a[href='/llms.txt']"
  end

  test "links to the agents page from every page" do
    get list_path(lists(:mine))

    assert_select ".site-footer a[href='#{agents_path}']"
  end

  test "tells agents how to use the service in llms.txt" do
    get "/llms.txt"

    assert_response :success
    assert_equal "text/markdown", response.media_type
    assert_match(/\A# Bibliotecas de Navarra/, response.body)
    assert_includes response.body, mcp_url
    assert_includes response.body, "#{root_url}?q="
    assert_includes response.body, "#{root_url}records/"
    assert_includes response.body, libraries_url(format: :md)
  end

  test "lets agents read llms.txt, the agents page and the Markdown pages, and nothing else" do
    get "/robots.txt"

    [ "Allow: /llms.txt", "Allow: /agentes", "Allow: /*.md$", "Allow: /*format=md", "Disallow: /" ].each do |line|
      assert_includes response.body, line
    end
  end

  test "answers in Markdown when the catalog is unavailable" do
    Rails.cache.clear
    with_opac_host("localhost") { get root_path(q: "Patria", format: :md) }

    assert_response :service_unavailable
    assert_equal "text/markdown", response.media_type
    assert_match(/no está disponible/, response.body)
  end

  class LiveTest < ActionDispatch::IntegrationTest
    setup do
      skip "Set OPAC_LIVE=1 to run tests against the real OPAC" unless ENV["OPAC_LIVE"]
    end

    test "searches in Markdown" do
      get root_path(q: "Patria Aramburu", format: :md)

      assert_response :success
      assert_equal "text/markdown", response.media_type
      assert_match(/\d+ resultados/, response.body)
      assert_includes response.body, "[Patria](#{record_url("554980", format: :md)})"
      assert_includes response.body, "page=2"
    end

    test "lists the libraries and their codes in Markdown" do
      get root_path(format: :md)

      assert_includes response.body, "Pamplona-San Pedro: `BPN/BP21`"
    end

    test "shows a record and its copies in Markdown" do
      get record_path("554980", format: :md)

      assert_response :success
      assert_match(/\A# Patria/, response.body)
      assert_includes response.body, "## Ejemplares"
      assert_match(/### Pamplona-San Pedro — \d+ de \d+ disponibles/, response.body)
      assert_includes response.body, "https://www.navarra.es/opac/abnetcl.exe?TITN=554980"
    end
  end
end
