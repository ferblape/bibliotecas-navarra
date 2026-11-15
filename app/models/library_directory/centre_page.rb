class LibraryDirectory
  # The page of a centre in the directory of navarra.es, with its address and contacts.
  class CentrePage
    URL = "https://www.navarra.es/es/w/centro/"

    def initialize(html, slug:)
      @document = Nokogiri::HTML(html)
      @slug = slug
    end

    def location
      Location.new(name: @document.at("h1").text.squish, address:, phones: contacts("tel:"), emails: contacts("mailto:"), url: URL + @slug)
    end

    private
      def address
        node = @document.at(".direccion address") or return
        node.css("br").each { it.replace(", ") }
        node.text.squish.presence
      end

      def contacts(scheme)
        @document.css(".direccion a[href^='#{scheme}']").map { it["href"].delete_prefix(scheme).strip }.uniq
      end
  end
end
