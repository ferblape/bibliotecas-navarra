require "test_helper"

class LayoutTest < ActionDispatch::IntegrationTest
  test "asks visitors not to abuse the service" do
    get list_path(lists(:mine))

    assert_select ".site-footer", /Es un servicio abierto a todos: por favor, no abuses de él\./
  end

  test "shows how many records the list of this browser keeps" do
    cookies[:list] = lists(:mine).token

    get list_path(lists(:mine))

    assert_select ".site-header__list svg"
    assert_select ".site-header__list .site-header__count", "2"
  end

  test "puts the tagline under the name of the site" do
    get list_path(lists(:mine))

    assert_select ".site-header .site-header__brand" do
      assert_select ".site-header__name"
      assert_select ".site-header__tagline"
    end
  end
end
