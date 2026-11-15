module Opac
  class ResultsPage
    def initialize(html, page: 1)
      @document = Nokogiri::HTML(html)
      @page = page
    end

    def results
      Results.new(records: @document.css("li.c-docs_unit").map { record(it) }, total:, page: @page)
    end

    private
      # The paginator reads "1 / 10 de 11"; a search without results has no paginator.
      def total
        @document.at_css("p.c-paginator_count")&.text.to_s[/de (\d+)/, 1].to_i
      end

      def record(node)
        Record.new(
          **MarcFields.new(node).record_fields,
          publication: node.at_xpath(".//dt[normalize-space()='Editorial:']/following-sibling::dd")&.text&.squish,
          material: node.at_css(".c-docs_mat i[title]")&.[]("title")
        )
      end
  end
end
