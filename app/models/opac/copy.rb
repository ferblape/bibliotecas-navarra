module Opac
  Copy = Data.define(:library_code, :library_name, :branch, :location, :status, :call_number, :format, :availability) do
    def available?
      availability == "Disponible"
    end
  end
end
