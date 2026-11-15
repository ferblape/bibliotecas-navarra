require "test_helper"

class Opac::LibrariesPageTest < ActiveSupport::TestCase
  setup do
    @libraries = Opac::LibrariesPage.new(opac_fixture("home")).libraries
  end

  test "rejects a page without libraries" do
    assert_raises(Opac::UnexpectedPage) { Opac::LibrariesPage.new("<html><body>Error 205</body></html>").libraries }
  end

  test "reads every library with its code and name" do
    san_pedro = @libraries.find { it.code == "BPN/BP21" }

    assert_equal "Pamplona-San Pedro", san_pedro.name
    assert_equal "BP21", san_pedro.copies_code
  end

  test "leaves out the groups of libraries" do
    assert_not_includes @libraries.map(&:code), "BPN"
    assert_not_includes @libraries.map(&:code), "/"
  end

  test "strips the indentation of names" do
    assert_includes @libraries.map(&:name), "Biblioteca de Navarra - Nafarroako Liburutegia"
    assert_includes @libraries.map(&:name), "Archivo Administrativo"
  end
end
