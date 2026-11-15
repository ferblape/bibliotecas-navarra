require "test_helper"

class Opac::RecordPageTest < ActiveSupport::TestCase
  setup do
    @record = Opac::RecordPage.new(opac_fixture("record")).record
  end

  test "rejects a page that is not a record" do
    assert_raises(Opac::UnexpectedPage) { Opac::RecordPage.new(opac_fixture("home")).record }
  end

  test "reads the fields of the record" do
    assert_equal "554980", @record.id
    assert_equal "Patria", @record.title
    assert_equal "Aramburu, Fernando (1959- )", @record.author
    assert_equal "Barcelona : Tusquets, 2016.", @record.publication
    assert_equal "2016", @record.year
    assert_equal "978-84-9066-319-6", @record.isbn
    assert_equal "Monografías", @record.material
  end

  test "reads the copies of every library" do
    copies = @record.copies.select { it.library_code == "BP21" }

    assert_equal 2, copies.size
    copy = copies.first
    assert_equal "Pamplona-San Pedro", copy.library_name
    assert_equal "PNA-San Pedro", copy.branch
    assert_equal "DEPÓSITOS", copy.location
    assert_equal "Prestable domicilio", copy.status
    assert_equal "D 304", copy.call_number
    assert_equal "Libros", copy.format
    assert_equal "Disponible", copy.availability
    assert copy.available?
  end

  test "marks loaned copies as not available" do
    loaned = @record.copies.find { it.availability.start_with?("Prestado") }

    assert_not loaned.available?
  end

  test "strips the padding of library names" do
    assert_includes @record.copies.map(&:library_name), "Biblioteca de Navarra - Nafarroako Liburutegia"
  end
end
