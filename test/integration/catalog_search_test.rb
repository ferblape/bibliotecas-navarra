require "test_helper"

class CatalogSearchTest < ActionDispatch::IntegrationTest
  test "tells that the catalog is unavailable when the OPAC is down" do
    Rails.cache.clear
    with_opac_host("localhost") { get root_path(q: "Patria") }

    assert_response :service_unavailable
    assert_select "h1", /no está disponible/
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

    test "shows a record with the copies of the chosen library first" do
      get root_path(library: SAN_PEDRO)
      get record_path("554980")

      assert_response :success
      assert_select "h1", "Patria"
      assert_select "a[href='https://www.navarra.es/opac/abnetcl.exe?TITN=554980']"
      assert_select ".copies details[open]", 1
      assert_select ".copies details[open] summary", /Pamplona-San Pedro/
      assert_select ".copies details:not([open])", minimum: 10
    end

    private
      def results_total
        css_select(".results-count").first.text[/[\d.]+/].delete(".").to_i
      end
  end
end
