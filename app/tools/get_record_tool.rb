class GetRecordTool < CatalogTool
  tool_name "get_record"
  description <<~TEXT.squish
    Shows a record of the catalog of the Bibliotecas Públicas de Navarra with its copies: the library holding each one,
    its call number and whether it is available for loan. A record can have copies in dozens of libraries, so pass a
    library to get only its copies.
  TEXT
  input_schema(
    properties: {
      id: { type: "string", minLength: 1, description: "Id of the record, as returned by search_catalog" },
      library: { type: "string", description: "Code of a library from list_libraries, to get only its copies" }
    },
    required: [ "id" ]
  )
  annotations read_only_hint: true, destructive_hint: false, idempotent_hint: true, open_world_hint: true

  def self.answer(id:, server_context:, library: nil)
    holding_library = Catalog.libraries.find { it.code == library } if library
    return error("There is no library #{library}. Use list_libraries for their codes.") if library && !holding_library

    record = Catalog.record(id)
    copies = holding_library ? record.copies.select { it.library_code == holding_library.copies_code } : record.copies
    respond record_data(record, server_context:).merge(copies: copies.map { it.to_h.merge(available: it.available?) })
  end
end
