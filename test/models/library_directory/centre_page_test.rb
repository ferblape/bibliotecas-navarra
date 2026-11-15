require "test_helper"

class LibraryDirectory::CentrePageTest < ActiveSupport::TestCase
  test "reads the address, phones and emails of a centre" do
    location = LibraryDirectory::CentrePage.new(file_fixture("directory/pamplona_san_pedro.html").read, slug: "biblioteca-de-pamplona-san-pedro").location

    assert_equal "Biblioteca de Pamplona-San Pedro", location.name
    assert_equal "Calle Virgen del Río, s/n, 31014 Pamplona / Iruña", location.address
    assert_equal [ "948136664" ], location.phones
    assert_equal [ "biblispe@navarra.es", "biblioteca.sanpedro@navarra.es" ], location.emails
    assert_equal "https://www.navarra.es/es/w/centro/biblioteca-de-pamplona-san-pedro", location.url
  end

  test "reads every phone of a centre" do
    location = LibraryDirectory::CentrePage.new(file_fixture("directory/ablitas.html").read, slug: "biblioteca-de-ablitas").location

    assert_equal "Avenida de Tudela, 27, 31523 Ablitas", location.address
    assert_equal [ "948843030", "948813623" ], location.phones
  end
end
