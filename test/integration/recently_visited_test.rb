require "test_helper"

class RecentlyVisitedTest < ActionDispatch::IntegrationTest
  setup do
    Rails.cache.write([ "catalog", "libraries" ], [ Opac::Library.new(code: "BPN/BP21", name: "Pamplona-San Pedro") ])
  end

  teardown do
    Rails.cache.clear
  end

  test "shows the records visited last on the home page" do
    sign_cookie :recent_records, [ { id: "554980", title: "Patria", author: "Aramburu, Fernando (1959- )", isbn: "978-84-9066-319-6" } ]

    get root_path

    assert_select ".recent-records .result a[href='#{record_path("554980")}']", "Patria"
  end

  test "hides them when there are none" do
    get root_path
    assert_select ".recent-records", 0
  end

  class LiveTest < ActionDispatch::IntegrationTest
    setup do
      skip "Set OPAC_LIVE=1 to run tests against the real OPAC" unless ENV["OPAC_LIVE"]
    end

    test "remembers the records visited" do
      get record_path("554980")
      get root_path

      assert_select ".recent-records .result a[href='#{record_path("554980")}']", "Patria"
    end
  end

  private
    def sign_cookie(name, value)
      jar = ActionDispatch::Request.new(Rails.application.env_config.deep_dup).cookie_jar
      jar.signed[name] = value
      cookies[name] = jar[name]
    end
end
