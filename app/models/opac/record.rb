module Opac
  Record = Data.define(:id, :title, :responsibility, :author, :publication, :year, :isbn, :material, :copies) do
    def initialize(copies: [], **fields)
      super
    end

    def opac_url
      Session.entry_url(TITN: id)
    end

    def self.cover_url(isbn)
      "https://covers.openlibrary.org/b/isbn/#{isbn.delete("-")}-M.jpg" if isbn
    end

    def cover_url
      self.class.cover_url(isbn)
    end
  end
end
