class ListLibrariesTool < CatalogTool
  tool_name "list_libraries"
  description "Lists the libraries of the Bibliotecas Públicas de Navarra with the code that narrows a search or a record's copies to one of them."
  annotations read_only_hint: true, destructive_hint: false, idempotent_hint: true, open_world_hint: true

  def self.answer(server_context:)
    respond libraries: Catalog.libraries.map(&:to_h)
  end
end
