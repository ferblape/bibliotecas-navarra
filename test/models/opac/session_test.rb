require "test_helper"

class Opac::SessionTest < ActiveSupport::TestCase
  test "reads the session URL from the entry page" do
    entry = '<meta http-equiv="Refresh" content="0; URL=/opac/abnetcl.exe/OhNCwNpVndf0FIhyKn1uCKYekFI?ACC=101" />'

    assert_equal "/opac/abnetcl.exe/OhNCwNpVndf0FIhyKn1uCKYekFI?ACC=101", Opac::Session.session_url(entry)
  end

  test "is refused when the entry page does not lead to a session" do
    assert_raises(Opac::Session::Refused) { Opac::Session.session_url(opac_fixture("home")) }
  end

  test "presents itself to the OPAC as one of several ordinary browsers" do
    user_agents = Opac::Session::USER_AGENTS

    assert_operator user_agents.uniq.size, :>, 3
    user_agents.each do |user_agent|
      assert_match %r{\AMozilla/5\.0 \(.+\) .+/[\d.]+\z}, user_agent
      assert_no_match(/bibliotecas|catalog/i, user_agent)
    end
  end

  class LiveTest < ActiveSupport::TestCase
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

    test "closes the session at the end of the block" do
      session = Opac::Session.open(ACC: 101) { it }

      assert_includes session.get(ACC: 101), "timeout.htm"
    end

    test "opens a record by its id" do
      record = Opac::RecordPage.new(Opac::Session.open(TITN: 554980).page).record

      assert_equal "554980", record.id
      assert_equal "Patria", record.title
    end
  end
end
