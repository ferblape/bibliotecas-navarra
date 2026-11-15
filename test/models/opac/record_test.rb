require "test_helper"

class Opac::RecordTest < ActiveSupport::TestCase
  test "links to the record in the OPAC" do
    record = Opac::Record.new(id: "554980", title: "Patria", responsibility: nil, author: nil, publication: nil, year: nil, isbn: nil, material: nil)

    assert_equal "https://www.navarra.es/opac/abnetcl.exe?TITN=554980", record.opac_url
  end
end
