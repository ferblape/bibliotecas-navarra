require "test_helper"

class BookmarkTest < ActiveSupport::TestCase
  test "shows the cover of its ISBN" do
    assert_equal "https://covers.openlibrary.org/b/isbn/9788490663196-M.jpg", bookmarks(:patria).cover_url
    assert_nil bookmarks(:madre_patria).cover_url
  end
end
