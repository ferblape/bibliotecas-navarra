module SearchesHelper
  FIELD_LABELS = { any: "Todo", title: "Título", author: "Autor", subject: "Materia" }.freeze

  def field_options
    FIELD_LABELS.map { |field, label| [ label, field ] }
  end

  # The current search with another query, from its first page.
  def search_params(query)
    request.query_parameters.except("page").merge(q: query)
  end

  def number_es(number)
    number_with_delimiter(number, delimiter: ".")
  end
end
