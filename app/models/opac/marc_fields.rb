module Opac
  # Reads the hidden block of MARC fields the OPAC renders next to every record.
  class MarcFields
    def initialize(node)
      @block = node.at_css("p.c-docs_marc")
    end

    def [](field)
      text = @block.at_css(".js-#{field}")&.text&.squish
      text.presence
    end

    def record_fields
      title, responsibility = self[:T245].split(" / ", 2)
      { id: self[:TITN], title:, responsibility:, author: self[:T1XX], year: self[:FEPU], isbn: self[:T020a] }
    end
  end
end
