require "test_helper"

class LibraryDirectoryTest < ActiveSupport::TestCase
  setup do
    @directory = LibraryDirectory.new(file_fixture("libraries.yml"))
  end

  test "reads the libraries with their locations" do
    san_pedro = @directory.find("BPN/BP21")

    assert_equal "Pamplona-San Pedro", san_pedro.name
    assert_equal "Calle Virgen del Río, s/n, 31014 Pamplona / Iruña", san_pedro.locations.first.address
    assert_equal [ "948136664" ], san_pedro.locations.first.phones
  end

  test "finds a library by the code its copies carry" do
    assert_equal "Pamplona-San Pedro", @directory.find_by_copies_code("BP21").name
    assert_nil @directory.find_by_copies_code("BP99")
  end

  test "links each location to Google Maps by its address" do
    location = @directory.find("BPN/BP21").locations.first

    assert_equal "https://www.google.com/maps/search/?api=1&query=Calle+Virgen+del+R%C3%ADo%2C+s%2Fn%2C+31014+Pamplona+%2F+Iru%C3%B1a", location.map_url
  end

  test "tells public libraries from specialized ones" do
    assert @directory.find("BPN/BP21").public?
    assert_not @directory.find("BEN/BAN").public?
  end

  test "keeps libraries without a known location" do
    assert_empty @directory.find("BEN/BAN").locations
  end
end
