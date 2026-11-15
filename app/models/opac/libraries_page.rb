module Opac
  class LibrariesPage
    def initialize(html)
      @document = Nokogiri::HTML(html)
    end

    # Groups of libraries ("BPN") and "all libraries" ("/") have codes without a slash in between.
    def libraries
      libraries = @document.css("select#subcat option").filter_map do |option|
        code = option["value"]
        Library.new(code:, name: option.text.sub(/\A[\s >]+/, "").strip) if code.match?(%r{\A\w+/\w})
      end
      libraries.presence or raise UnexpectedPage, "No libraries in the page"
    end
  end
end
