require "test_helper"

class Opac::RecordTest < ActiveSupport::TestCase
  setup do
    @record = Opac::Record.new(id: "554980", title: "Patria", responsibility: nil, author: nil, publication: nil, year: nil,
                               isbn: "978-84-9066-319-6", material: nil)
  end

  test "links to the record in the OPAC" do
    assert_equal "https://www.navarra.es/opac/abnetcl.exe?TITN=554980", @record.opac_url
  end

  # Open Library serves a blank image when it has no cover, so the page shows no broken image.
  test "takes the cover from Open Library by ISBN" do
    assert_equal "https://covers.openlibrary.org/b/isbn/9788490663196-M.jpg", @record.cover_url
  end

  test "has no cover without an ISBN" do
    assert_nil @record.with(isbn: nil).cover_url
  end
end
