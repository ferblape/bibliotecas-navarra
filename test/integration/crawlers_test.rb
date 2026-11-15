require "test_helper"

class CrawlersTest < ActionDispatch::IntegrationTest
  GOOGLEBOT = "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
  FIREFOX = "Mozilla/5.0 (Macintosh; Intel Mac OS X 14.5; rv:132.0) Gecko/20100101 Firefox/132.0"

  test "robots.txt disallows everything" do
    get "/robots.txt"

    assert_response :success
    assert_match(/^User-agent: \*\nDisallow: \/$/, response.body)
  end

  test "asks search engines not to index, follow or archive any page" do
    get list_path(lists(:mine)), headers: { "User-Agent" => FIREFOX }

    assert_response :success
    assert_equal "noindex, nofollow, noarchive", response.headers["X-Robots-Tag"]
  end

  test "sends no referrer to the sites pages link to" do
    get list_path(lists(:mine)), headers: { "User-Agent" => FIREFOX }

    assert_equal "no-referrer", response.headers["Referrer-Policy"]
  end

  test "turns crawlers away before they reach the catalog" do
    [ GOOGLEBOT, "GPTBot/1.1", "Mozilla/5.0 (compatible; bingbot/2.0)", "facebookexternalhit/1.1",
      "Mozilla/5.0 (compatible; Baiduspider/2.0)", "ia_archiver" ].each do |user_agent|
      get list_path(lists(:mine)), headers: { "User-Agent" => user_agent }

      assert_response :forbidden, user_agent
    end
  end

  test "turns crawlers away from the MCP endpoint too" do
    post "/mcp", headers: { "User-Agent" => GOOGLEBOT }

    assert_response :forbidden
  end

  test "lets crawlers read robots.txt" do
    get "/robots.txt", headers: { "User-Agent" => GOOGLEBOT }

    assert_response :success
  end
end
