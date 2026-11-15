# A record saved in a list. It keeps the title, author and ISBN so the list
# shows without asking the OPAC for each record.
class Bookmark < ApplicationRecord
  belongs_to :list

  def cover_url
    Opac::Record.cover_url(isbn)
  end
end
