require "test_helper"

class BookmarksTest < ActionDispatch::IntegrationTest
  test "opens a list and makes it the list of this browser when it has none" do
    get list_path(lists(:mine))

    assert_response :success
    assert_select ".bookmark a[href='#{record_path("554980")}']", "Patria"
    assert_select "input[value='#{list_url(lists(:mine))}']"
    assert_select "meta[name=robots][content=noindex]", visible: false
    assert_equal lists(:mine).token, cookies[:list]
  end

  test "asks before replacing the list of this browser" do
    cookies[:list] = lists(:mine).token

    get list_path(lists(:someone_elses))
    assert_select ".bookmark", 1
    assert_select "form[action='#{list_selection_path(lists(:someone_elses))}'] button", /Usar esta lista/
    assert_equal lists(:mine).token, cookies[:list]

    post list_selection_path(lists(:someone_elses))
    assert_redirected_to list_path(lists(:someone_elses))
    assert_equal lists(:someone_elses).token, cookies[:list]
  end

  test "forgets the list in this browser without deleting it" do
    cookies[:list] = lists(:mine).token

    delete list_selection_path(lists(:mine))

    assert_redirected_to root_path
    assert cookies[:list].blank?
    assert List.exists?(lists(:mine).id)
  end

  test "links to the list of this browser from every page" do
    cookies[:list] = lists(:mine).token

    get list_path(lists(:someone_elses))

    assert_select ".site-header a[href='#{list_path(lists(:mine))}']", "Mi lista"
  end

  test "removes a bookmark from the list of this browser" do
    cookies[:list] = lists(:mine).token

    delete record_bookmark_path("554980"), headers: { "HTTP_REFERER" => list_url(lists(:mine)) }

    assert_redirected_to list_url(lists(:mine))
    assert_not lists(:mine).bookmarked?("554980")
  end

  test "does not find a list with an unknown token" do
    get list_path("unknown")

    assert_response :not_found
  end

  class LiveTest < ActionDispatch::IntegrationTest
    setup do
      skip "Set OPAC_LIVE=1 to run tests against the real OPAC" unless ENV["OPAC_LIVE"]
    end

    test "saves a record in a new list and asks to keep its URL" do
      assert_difference -> { List.count } do
        post record_bookmark_path("554980")
      end

      list = List.last
      assert_equal list.token, cookies[:list]
      assert list.bookmarked?("554980")

      follow_redirect!
      assert_select ".notice", /Guarda esta dirección/
      assert_select ".notice a[href='#{list_url(list)}']"
      assert_select "form[action='#{record_bookmark_path("554980")}'] button", /Quitar de mi lista/
    end

    test "saves a record in the list of this browser" do
      cookies[:list] = lists(:mine).token
      get record_path("566437")
      assert_select "form[action='#{record_bookmark_path("566437")}'] button", /Guardar en mi lista/

      assert_no_difference -> { List.count } do
        post record_bookmark_path("566437")
      end

      assert lists(:mine).bookmarked?("566437")
    end
  end
end
