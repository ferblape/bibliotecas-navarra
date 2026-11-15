require "test_helper"

class RecentRecordsTest < ActiveSupport::TestCase
  test "puts the last visited record first, without repeating it" do
    recent = RecentRecords.new([]).add(record("1")).add(record("2")).add(record("1"))

    assert_equal %w[1 2], recent.map(&:id)
  end

  test "keeps the last visits only" do
    recent = (1..10).reduce(RecentRecords.new([])) { |recent, id| recent.add(record(id.to_s)) }

    assert_equal %w[10 9 8 7 6 5 4 3], recent.map(&:id)
  end

  test "survives a round trip through the cookie" do
    cookie = RecentRecords.new([]).add(record("554980", title: "Patria", isbn: "978-84-9066-319-6")).to_cookie
    entry = RecentRecords.new(JSON.parse(cookie.to_json)).first

    assert_equal [ "554980", "Patria", "Aramburu, Fernando (1959- )" ], [ entry.id, entry.title, entry.author ]
    assert_equal "https://covers.openlibrary.org/b/isbn/9788490663196-M.jpg", entry.cover_url
  end

  test "shortens long titles and authors so the cookie stays small" do
    recent = RecentRecords.new([]).add(record("1", title: "Patria " * 40, author: "Aramburu " * 40))

    assert_operator recent.first.title.length, :<=, RecentRecords::TEXT_LENGTH
    assert_operator recent.first.author.length, :<=, RecentRecords::TEXT_LENGTH
  end

  test "ignores entries it cannot read" do
    recent = RecentRecords.new([ { "id" => "1", "title" => "Patria" }, "garbage", { "nope" => 1 } ])

    assert_equal %w[1], recent.map(&:id)
  end

  private
    def record(id, title: "Libro #{id}", author: "Aramburu, Fernando (1959- )", isbn: nil)
      Opac::Record.new(id:, title:, responsibility: nil, author:, publication: nil, year: nil, isbn:, material: nil)
    end
end
