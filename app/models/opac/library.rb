module Opac
  Library = Data.define(:code, :name) do
    # Copies in a record name their library by the last segment of its code ("BP21" for "BPN/BP21").
    def copies_code
      code.split("/").last
    end
  end
end
