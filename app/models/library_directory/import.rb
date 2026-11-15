require "net/http"

class LibraryDirectory
  # Reads the directory of libraries of navarra.es and matches its centres with the libraries
  # of the OPAC by name. config/library_overrides.yml gives the centres of the libraries whose
  # names do not match, and runs in GitHub Actions monthly, so changes arrive as pull requests.
  class Import
    HOST = "https://www.navarra.es"
    LISTING_PATH = "/es/bibliotecas/directorio/-/search/filter/0/sort/%<sort>s/facet/0/tag/0/date/0/rpp/20/page/%<page>d"
    # The search of the directory returns 100 results at most, so it is read sorted both ways.
    SORTS = %w[ publish_asc publish_desc ].freeze
    OVERRIDES_PATH = Rails.root.join("config/library_overrides.yml")
    PAUSE = 1

    def initialize(overrides: YAML.load_file(OVERRIDES_PATH))
      @overrides = overrides
    end

    def libraries(opac_libraries = Catalog.libraries)
      centres = SORTS.flat_map { centres_sorted_by(it) }.uniq
      opac_libraries.map do |library|
        { "code" => library.code, "name" => library.name,
          "locations" => centre_slugs(library, centres).map { location(it).to_h.stringify_keys } }
      end
    end

    def centre_slugs(library, centres)
      return Array(@overrides[library.code]) if @overrides.key?(library.code)

      # "Altsasu/Alsasua" matches "Alsasua", and "Aurizberri/Espinal" matches "Aurizberri - Espinal".
      names = [ library.name, *library.name.split(%r{\s*/\s*|\s+-\s+}) ].map { normalize(it) }
      centres.select { names.include?(normalize(it.name)) }.map(&:slug).first(1)
    end

    private
      def centres_sorted_by(sort)
        (1..).lazy.map { ListingPage.new(fetch(format(LISTING_PATH, sort:, page: it))).centres }.take_while(&:any?).to_a.flatten
      end

      def location(slug)
        CentrePage.new(fetch("/es/w/centro/#{slug}"), slug:).location
      end

      def normalize(name)
        I18n.transliterate(name).downcase.sub(/\Abiblioteca (publica |municipal )?(de la |del |de )?/, "").gsub(/[^a-z0-9]+/, " ").strip
      end

      def fetch(path)
        sleep PAUSE
        response = Net::HTTP.get_response(URI(HOST + path), "User-Agent" => "BibliotecasNavarra/1.0 (https://bibliotecas-navarra.fly.dev)")
        response.value
        response.body.force_encoding(Encoding::UTF_8)
      end
  end
end
