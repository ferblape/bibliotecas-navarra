module Opac
  class RecordPage
    COPY_COLUMNS = %i[location status call_number format availability].freeze

    def initialize(html)
      @document = Nokogiri::HTML(html)
    end

    def record
      marc = MarcFields.new(@document)
      Record.new(
        **marc.record_fields,
        publication: marc[:nedit],
        material: @document.at_css(".doc_type i[title]")&.[]("title"),
        copies: @document.css("div.copias_data").flat_map { library_copies(it) }
      )
    end

    private
      def library_copies(node)
        library_code = node.at_css("h3")["id"].delete_prefix("copias_bib")
        node.css("table[data-sudesc]").flat_map do |table|
          table.css("tbody tr").map do |row|
            columns = row.css("td").first(COPY_COLUMNS.size).map { cell_value(it) }
            Copy.new(library_code:, library_name: table["data-bidesc"].strip, branch: table["data-sudesc"].strip,
                     **COPY_COLUMNS.zip(columns).to_h)
          end
        end
      end

      # Each cell repeats its column name in a label for small screens.
      def cell_value(cell)
        cell.dup.tap { it.at_css(".copias_label")&.remove }.text.squish
      end
  end
end
