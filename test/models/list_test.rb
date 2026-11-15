require "test_helper"

class ListTest < ActiveSupport::TestCase
  test "is reached through a secret token" do
    list = List.create!

    assert_match(/\A[a-zA-Z0-9]{24}\z/, list.to_param)
    assert_equal list.token, list.to_param
  end

  test "bookmarks a record once, keeping its title, author and ISBN" do
    list = List.create!
    record = Opac::Record.new(id: "554980", title: "Patria", responsibility: "Fernando Aramburu.", author: "Aramburu, Fernando (1959- )",
                              publication: nil, year: nil, isbn: "978-84-9066-319-6", material: nil)

    2.times { list.bookmark(record) }

    assert_equal [ [ "554980", "Patria", "Aramburu, Fernando (1959- )", "978-84-9066-319-6" ] ],
                 list.bookmarks.pluck(:record_id, :title, :author, :isbn)
  end

  test "knows which records it has bookmarked" do
    assert lists(:mine).bookmarked?("554980")
    assert_not lists(:mine).bookmarked?("640001")
  end

  test "lists the newest bookmarks first" do
    assert_equal [ "Años lentos", "Patria" ], lists(:mine).bookmarks.map(&:title)
  end
end
