class ListLibrariesTool < CatalogTool
  tool_name "list_libraries"
  description <<~TEXT.squish
    Lists the libraries of the Bibliotecas Públicas de Navarra with the code that narrows a search or a record's copies
    to one of them, and where each one is: address, phones, emails, a Google Maps link and its official page with the
    opening hours.
  TEXT
  annotations read_only_hint: true, destructive_hint: false, idempotent_hint: true, open_world_hint: true

  def self.answer(server_context:)
    respond libraries: Catalog.libraries.map { |library| library.to_h.merge(locations: locations(library)) }
  end

  def self.locations(library)
    LibraryDirectory.find(library.code)&.locations.to_a.map { it.to_h.merge(map_url: it.map_url) }
  end
end
