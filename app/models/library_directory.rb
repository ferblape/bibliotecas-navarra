# Where the libraries are and how to reach them, from the directory of libraries of navarra.es.
# config/libraries.yml holds it and `bin/rails libraries:import` refreshes it (see LibraryDirectory::Import).
class LibraryDirectory
  PATH = Rails.root.join("config/libraries.yml")

  Library = Data.define(:code, :name, :locations) do
    # Specialized libraries (archives, museums...) have codes under BEN; the rest are public.
    def public?
      !code.start_with?("BEN/")
    end

    def copies_code
      code.split("/").last
    end

    def anchor
      code.parameterize
    end
  end

  Location = Data.define(:name, :address, :phones, :emails, :url) do
    def map_url
      "https://www.google.com/maps/search/?api=1&query=#{CGI.escape(address)}" if address
    end
  end

  class << self
    delegate :all, :find, :find_by_copies_code, to: :default

    def default
      @default ||= new(PATH)
    end
  end

  attr_reader :all

  def initialize(path)
    @all = YAML.load_file(path).map do |library|
      Library.new(code: library["code"], name: library["name"],
        locations: library["locations"].map { Location.new(**it.symbolize_keys) })
    end
  end

  def find(code)
    all.find { it.code == code }
  end

  def find_by_copies_code(copies_code)
    all.find { it.copies_code == copies_code }
  end
end
