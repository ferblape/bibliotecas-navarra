require "test_helper"

class LibraryDirectory::ListingPageTest < ActiveSupport::TestCase
  test "reads the centres of a page of the directory" do
    centres = LibraryDirectory::ListingPage.new(file_fixture("directory/listing.html").read).centres

    assert_equal 20, centres.size
    assert_includes centres, LibraryDirectory::Centre.new(slug: "biblioteca-de-ablitas", name: "Biblioteca de Ablitas")
  end

  test "reads no centres past the last page" do
    assert_empty LibraryDirectory::ListingPage.new("<html><body></body></html>").centres
  end
end
