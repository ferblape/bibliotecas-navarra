require "test_helper"

class ContentSecurityPolicyTest < ActionDispatch::IntegrationTest
  test "restricts what pages can load and who can frame them" do
    get list_path(lists(:mine))

    policy = response.headers["Content-Security-Policy"]
    assert_includes policy, "default-src 'self'"
    assert_includes policy, "img-src 'self' https: data:"
    assert_includes policy, "object-src 'none'"
    assert_includes policy, "frame-ancestors 'none'"
    assert_includes policy, "form-action 'self'"
  end

  test "lets the import map run through a nonce" do
    get list_path(lists(:mine))

    nonce = css_select("script[type=importmap]").first["nonce"]
    assert nonce.present?
    assert_includes response.headers["Content-Security-Policy"], "'nonce-#{nonce}'"
  end
end
