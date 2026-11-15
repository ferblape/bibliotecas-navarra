require "test_helper"

class Opac::ResultsPageTest < ActiveSupport::TestCase
  test "reads the total and the records of the page" do
    results = Opac::ResultsPage.new(opac_fixture("results_all")).results

    assert_equal 11, results.total
    assert_equal 10, results.records.size
  end

  test "reads the fields of each record" do
    record = Opac::ResultsPage.new(opac_fixture("results_all")).results.records.third

    assert_equal "554980", record.id
    assert_equal "Patria", record.title
    assert_equal "Fernando Aramburu.", record.responsibility
    assert_equal "Aramburu, Fernando (1959- )", record.author
    assert_equal "Barcelona : Tusquets, 2016.", record.publication
    assert_equal "2016", record.year
    assert_equal "978-84-9066-319-6", record.isbn
    assert_equal "Monografías", record.material
  end

  test "leaves missing fields empty" do
    record = Opac::ResultsPage.new(opac_fixture("results_all")).results.records.last

    assert_equal "Patria [Vídeo] : todos somos parte de esta historia", record.title
    assert_nil record.author
    assert_nil record.isbn
    assert_equal "Videograbaciones", record.material
  end

  test "reads a search without results" do
    results = Opac::ResultsPage.new(opac_fixture("results_empty")).results

    assert_equal 0, results.total
    assert_empty results.records
  end

  test "rejects a page that is not a search result" do
    assert_raises(Opac::UnexpectedPage) { Opac::ResultsPage.new(opac_fixture("home")).results }
  end

  test "knows the pages around the current one" do
    first = Opac::ResultsPage.new(opac_fixture("results_all")).results
    second = Opac::ResultsPage.new(opac_fixture("results_all"), page: 2).results

    assert_equal 2, first.total_pages
    assert first.next_page?
    assert_not first.previous_page?
    assert second.previous_page?
    assert_not second.next_page?
  end
end
