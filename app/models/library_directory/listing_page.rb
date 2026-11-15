class LibraryDirectory
  # A page of results of the directory of libraries of navarra.es.
  class ListingPage
    def initialize(html)
      @document = Nokogiri::HTML(html)
    end

    def centres
      @document.css(".searcher-result a.searcher-result-title[href*='/centro/']").map do |link|
        Centre.new(slug: link["href"][%r{/centro/([^/?]+)}, 1], name: link.text.squish)
      end
    end
  end
end
