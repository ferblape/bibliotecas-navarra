require "test_helper"

class CatalogSearchTest < ActionDispatch::IntegrationTest
  test "tells that the catalog is unavailable when the OPAC is down" do
    Rails.cache.clear
    with_opac_host("localhost") { get root_path(q: "Patria") }

    assert_response :service_unavailable
    assert_select "h1", /no está disponible/
  end

  test "limits the requests of each visitor" do
    Rails.cache.clear
    with_opac_host("localhost") do
      30.times { get root_path(q: "Patria") }
      assert_response :service_unavailable

      get root_path(q: "Patria")
      assert_response :too_many_requests
    end
  ensure
    Rails.cache.clear
  end

  class LiveTest < ActionDispatch::IntegrationTest
    SAN_PEDRO = "BPN/BP21"

    setup do
      skip "Set OPAC_LIVE=1 to run tests against the real OPAC" unless ENV["OPAC_LIVE"]
    end

    test "shows the search form with every library" do
      get root_path

      assert_response :success
      assert_select "select[name=library] option[value='#{SAN_PEDRO}']", "Pamplona-San Pedro"
      assert_select ".result", 0
    end

    test "searches the whole catalog" do
      get root_path(q: "Patria")

      assert_response :success
      assert_select ".results-count", /\d+ resultados/
      assert_select ".result", 10

      get root_path(q: "Patria Aramburu")
      assert_select ".result a[href='#{record_path("554980")}']", "Patria"
    end

    test "searches in one library and remembers it" do
      get root_path(q: "Patria", library: SAN_PEDRO)

      assert_select ".result a[href='#{record_path("554980")}']", "Patria"
      assert_operator results_total, :<, 50

      get root_path
      assert_select "select[name=library] option[selected][value='#{SAN_PEDRO}']"
    end

    test "searches in one field" do
      get root_path(q: "Aramburu", field: "author", library: SAN_PEDRO)

      assert_select ".result .author" do |authors|
        assert authors.all? { it.text.include?("Aramburu") }
      end
      assert_select "select[name=field] option[selected][value=author]"
    end

    test "pages through the results" do
      get root_path(q: "Patria", page: 2)

      assert_select ".pagination", /Página 2 de \d+/
      assert_select ".pagination a[href*='page=3']"
      assert_select ".pagination a[href*='page=1']"
    end

    test "tells when there are no results" do
      get root_path(q: "xqzwvkjh")

      assert_select ".result", 0
      assert_select ".no-results", /xqzwvkjh/
    end

    test "suggests a correction for a misspelt search" do
      skip "Needs RAILS_MASTER_KEY for the Google Books API key" unless GoogleBooks.api_key
      get root_path(q: "ana cadabra", field: "title")

      assert_select ".suggestion a[href=?]", root_path(field: "title", q: "anna kadabra"), "anna kadabra"

      get root_path(q: "ana cadabra", field: "title", format: :md)
      assert_includes response.body, "¿Quisiste decir «anna kadabra»? #{root_url(field: "title", q: "anna kadabra", format: :md)}"
    end

    test "shows a record with the copies of the chosen library first" do
      get root_path(library: SAN_PEDRO)
      get record_path("554980")

      assert_response :success
      assert_select "h1", "Patria"
      assert_select "a[href='https://www.navarra.es/opac/abnetcl.exe?TITN=554980']"
      assert_select ".copies details[open]", 1
      assert_select ".copies details[open] summary", /Pamplona-San Pedro/
      assert_select ".copies details[open] summary a[href='#{libraries_path(anchor: "bpn-bp21")}']"
      assert_select ".copies details:not([open])", minimum: 10
    end

    test "goes back to the search from a record, but not to the record itself" do
      get record_path("554980"), headers: { "HTTP_REFERER" => root_url(q: "Patria") }
      assert_select "a.back[href='#{root_url(q: "Patria")}']"

      get record_path("554980"), headers: { "HTTP_REFERER" => record_url("554980") }
      assert_select "a.back[href='#{root_path}']"
    end

    private
      def results_total
        css_select(".results-count").first.text[/[\d.]+/].delete(".").to_i
      end
  end
end
