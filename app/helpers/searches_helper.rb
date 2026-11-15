module SearchesHelper
  FIELD_LABELS = { any: "Todo", title: "Título", author: "Autor", subject: "Materia" }.freeze

  def field_options
    FIELD_LABELS.map { |field, label| [ label, field ] }
  end

  def number_es(number)
    number_with_delimiter(number, delimiter: ".")
  end
end
