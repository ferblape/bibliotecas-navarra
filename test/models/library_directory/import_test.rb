require "test_helper"

class LibraryDirectory::ImportTest < ActiveSupport::TestCase
  CENTRES = [
    LibraryDirectory::Centre.new(slug: "biblioteca-de-ablitas", name: "Biblioteca de Ablitas"),
    LibraryDirectory::Centre.new(slug: "biblioteca-de-pamplona-san-pedro", name: "Biblioteca de Pamplona-San Pedro"),
    LibraryDirectory::Centre.new(slug: "biblioteca-de-alsasua", name: "Biblioteca de Alsasua"),
    LibraryDirectory::Centre.new(slug: "biblioteca-de-santesteban", name: "Biblioteca de Santesteban"),
    LibraryDirectory::Centre.new(slug: "biblioteca-de-espinal", name: "Biblioteca de Aurizberri - Espinal")
  ].freeze

  test "matches libraries to centres by name, ignoring accents, case and the word Biblioteca" do
    import = LibraryDirectory::Import.new(overrides: { "centres" => {} })

    assert_equal [ "biblioteca-de-ablitas" ], import.centre_slugs(Opac::Library.new(code: "BPN/BP57", name: "Ablitas"), CENTRES)
    assert_equal [ "biblioteca-de-pamplona-san-pedro" ], import.centre_slugs(Opac::Library.new(code: "BPN/BP21", name: "Pamplona-San Pedro"), CENTRES)
  end

  test "matches a library with a name in two languages by either of them" do
    import = LibraryDirectory::Import.new(overrides: { "centres" => {} })

    assert_equal [ "biblioteca-de-alsasua" ], import.centre_slugs(Opac::Library.new(code: "BPN/BP13", name: "Altsasu/Alsasua"), CENTRES)
  end

  test "matches a name written with a slash in the OPAC and a dash in the directory" do
    import = LibraryDirectory::Import.new(overrides: { "centres" => {} })

    assert_equal [ "biblioteca-de-espinal" ], import.centre_slugs(Opac::Library.new(code: "BPN/BP77", name: "Aurizberri/Espinal"), CENTRES)
  end

  test "takes the centres of a library from the overrides first" do
    import = LibraryDirectory::Import.new(overrides: { "centres" => { "BPN/BP89" => "biblioteca-de-santesteban", "BPN/BP88" => %w[ olaz sarriguren ], "BEN/BAN" => nil } })

    assert_equal [ "biblioteca-de-santesteban" ], import.centre_slugs(Opac::Library.new(code: "BPN/BP89", name: "Doneztebe"), CENTRES)
    assert_equal %w[ olaz sarriguren ], import.centre_slugs(Opac::Library.new(code: "BPN/BP88", name: "Egües, Valle de"), CENTRES)
    assert_empty import.centre_slugs(Opac::Library.new(code: "BEN/BAN", name: "Archivo de Navarra"), CENTRES)
  end

  test "takes the coordinates of a centre from the overrides before asking the geocoder" do
    import = LibraryDirectory::Import.new(overrides: { "coordinates" => { "biblioteca-de-pamplona-echavacoiz" => [ 42.79891, -1.67391 ] } })

    assert_equal [ 42.79891, -1.67391 ], import.coordinates("biblioteca-de-pamplona-echavacoiz", "Grupo Urdanoz. Avenida Aróstegui, s/n, 31009 Pamplona / Iruña")
  end

  test "finds no centre for an unknown library" do
    assert_empty LibraryDirectory::Import.new(overrides: { "centres" => {} }).centre_slugs(Opac::Library.new(code: "X/Y", name: "Atlántida"), CENTRES)
  end
end
