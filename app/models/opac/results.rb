module Opac
  class Results < Data.define(:records, :total, :page)
    PER_PAGE = 10

    def total_pages
      (total.to_f / PER_PAGE).ceil
    end

    def next_page?
      page < total_pages
    end

    def previous_page?
      page > 1
    end
  end
end
