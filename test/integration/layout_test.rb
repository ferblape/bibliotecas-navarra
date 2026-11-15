require "test_helper"

class LayoutTest < ActionDispatch::IntegrationTest
  test "asks visitors not to abuse the service" do
    get list_path(lists(:mine))

    assert_select ".site-footer", /Esto es un servicio público, por favor no abuses de él\./
  end

  test "puts the tagline under the name of the site" do
    get list_path(lists(:mine))

    assert_select ".site-header .site-header__brand" do
      assert_select ".site-header__name"
      assert_select ".site-header__tagline"
    end
  end
end
