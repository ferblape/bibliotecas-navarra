require "test_helper"

class Opac::SessionTest < ActiveSupport::TestCase
  setup do
    skip "Set OPAC_LIVE=1 to run tests against the real OPAC" unless ENV["OPAC_LIVE"]
  end

  test "opens a session on the home page" do
    session = Opac::Session.open(ACC: 101)

    assert_match %r{\A/opac/abnetcl\.exe/\w+\z}, session.path
    assert_includes Opac::LibrariesPage.new(session.page).libraries.map(&:code), "BPN/BP21"
  end

  test "returns pages in UTF-8" do
    page = Opac::Session.open(ACC: 101).page

    assert_equal Encoding::UTF_8, page.encoding
    assert_includes page, "Bibliotecas Públicas de Navarra"
  end

  test "searches with accented terms and pages through the results in the same session" do
    session = Opac::Session.open(ACC: 101)
    search = { ACC: 131, START: 1, FORM: 1, xindbt: "", xmismo: "on", FORM_DIGITAL: 9, xsface: "on", xsqf01: "año" }

    first = Opac::ResultsPage.new(session.post(search)).results
    second = Opac::ResultsPage.new(session.get(ACC: 161, DOC: 11), page: 2).results

    assert_operator first.total, :>, 10
    assert_equal first.total, second.total
    assert_not_equal first.records.map(&:id), second.records.map(&:id)
  end

  test "opens a record by its id" do
    record = Opac::RecordPage.new(Opac::Session.open(TITN: 554980).page).record

    assert_equal "554980", record.id
    assert_equal "Patria", record.title
  end
end
