require "test_helper"

class CartoCiudadTest < ActiveSupport::TestCase
  test "reads the point of a place in Navarra" do
    assert_equal [ 41.97530, -1.64006 ], CartoCiudad.point(file_fixture("carto_ciudad/portal.json").read)
    assert_equal [ 42.79302, -1.62031 ], CartoCiudad.point(file_fixture("carto_ciudad/town.json").read)
  end

  test "rejects places outside Navarra and empty answers" do
    assert_nil CartoCiudad.point(file_fixture("carto_ciudad/madrid.json").read)
    assert_nil CartoCiudad.point("")
  end

  test "looks for the street and number, then the street, then the town" do
    assert_equal [ "Avenida de Tudela 27, Ablitas", "Avenida de Tudela, Ablitas", "Ablitas" ],
      CartoCiudad.queries("Avenida de Tudela, 27, 31523 Ablitas")
  end

  test "leaves out what the geocoder does not understand" do
    assert_equal [ "Calle Virgen del Río, Pamplona", "Pamplona" ], CartoCiudad.queries("Calle Virgen del Río, s/n, 31014 Pamplona / Iruña")
    assert_equal [ "Plaza Mena, Puente la Reina", "Puente la Reina" ], CartoCiudad.queries("Plaza Mena s/n, 31100 Puente la Reina / Gares")
    assert_equal [ "Calle Merkatondoa 13, Estella", "Calle Merkatondoa, Estella", "Estella" ],
      CartoCiudad.queries("Calle Merkatondoa, 13 nave 4, 31200 Estella - Lizarra")
    assert_equal [ "Zentro Palacio Condestable, Pamplona", "Pamplona" ],
      CartoCiudad.queries(%("Zentro" Palacio Condestable, calle Mayor, 2, 31001 Pamplona / Iruña))
  end

  class LiveTest < ActiveSupport::TestCase
    setup do
      skip "Set CARTOCIUDAD_LIVE=1 to run tests against CartoCiudad" unless ENV["CARTOCIUDAD_LIVE"]
    end

    test "finds the point of an address" do
      latitude, longitude = CartoCiudad.coordinates("Avenida de Tudela, 27, 31523 Ablitas")

      assert_in_delta 41.975, latitude, 0.01
      assert_in_delta(-1.640, longitude, 0.01)
    end
  end
end
