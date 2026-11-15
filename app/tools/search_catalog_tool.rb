class SearchCatalogTool < CatalogTool
  tool_name "search_catalog"
  description <<~TEXT.squish
    Searches the catalog of the Bibliotecas Públicas de Navarra (books, films, music and more, mostly in Spanish and Basque).
    Returns #{Opac::Results::PER_PAGE} records per page with the total of matches. Use get_record for the copies of a record
    and whether they are available.
  TEXT
  input_schema(
    properties: {
      query: { type: "string", minLength: 1, description: "Words to look for" },
      field: { type: "string", enum: Catalog::FIELDS.keys.map(&:to_s), default: "any", description: "Where to look for the words" },
      library: { type: "string", description: "Code of a library from list_libraries, to search only its holdings" },
      page: { type: "integer", minimum: 1, default: 1 }
    },
    required: [ "query" ]
  )
  annotations read_only_hint: true, destructive_hint: false, idempotent_hint: true, open_world_hint: true

  def self.answer(query:, server_context:, field: "any", library: nil, page: 1)
    results = Catalog.search(query.squish, field: field.to_sym, library:, page:)
    respond total: results.total, page: results.page, total_pages: results.total_pages,
      records: results.records.map { record_data(it, server_context:) }
  end
end
