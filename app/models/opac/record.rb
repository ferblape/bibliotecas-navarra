module Opac
  Record = Data.define(:id, :title, :responsibility, :author, :publication, :year, :isbn, :material, :copies) do
    def initialize(copies: [], **fields)
      super
    end

    def cover_url
      "https://covers.openlibrary.org/b/isbn/#{isbn.delete("-")}-M.jpg?default=false" if isbn
    end
  end
end
