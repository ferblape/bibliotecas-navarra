require "test_helper"

class LibrariesTest < ActionDispatch::IntegrationTest
  test "lists every library with its address, a map and its contacts" do
    get libraries_path

    assert_response :success
    assert_select "h2", "Bibliotecas públicas"
    assert_select "h2", "Bibliotecas especializadas"
    assert_select ".library#bpn-bp21" do
      assert_select "h3", "Pamplona-San Pedro"
      assert_select "address", /Calle Virgen del Río, s\/n, 31014 Pamplona/
      assert_select "a[href^='https://www.google.com/maps/search/?api=1&query=Calle+Virgen+del+R']"
      assert_select "a[href='tel:948136664']"
      assert_select "a[href='https://www.navarra.es/es/w/centro/biblioteca-de-pamplona-san-pedro']"
    end
  end

  test "dials only the digits of a phone with a note" do
    get libraries_path

    assert_select ".library#bpn-bp13 a[href='tel:722695449']", /722695449 \(Whatsapp\)/
  end

  test "shows a library without a known location" do
    get libraries_path

    assert_select ".library#ben-ban h3", "Archivo de Navarra"
  end

  test "links to the libraries from every page" do
    get libraries_path

    assert_select ".site-footer a[href='#{libraries_path}']"
  end

  test "lists the libraries in Markdown" do
    get libraries_path(format: :md)

    assert_equal "text/markdown", response.media_type
    assert_includes response.body, "## Bibliotecas públicas"
    assert_includes response.body, "### Pamplona-San Pedro (`BPN/BP21`)"
    assert_includes response.body, "Calle Virgen del Río, s/n, 31014 Pamplona / Iruña"
    assert_includes response.body, "https://www.google.com/maps/search/?api=1&query="
    assert_match(/- Coordenadas: 42\.\d+, -1\.\d+/, response.body)
  end
end
