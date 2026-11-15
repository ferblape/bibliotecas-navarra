# The records this browser visited last, newest first. They live in a cookie, so they
# stay anonymous and show without asking the OPAC.
class RecentRecords
  include Enumerable

  LIMIT = 8
  TEXT_LENGTH = 70

  Entry = Data.define(:id, :title, :author, :isbn) do
    def cover_url
      Opac::Record.cover_url(isbn)
    end
  end

  def initialize(cookie)
    @entries = Array(cookie).filter_map { entry_from(it) }
  end

  def add(record)
    entry = Entry.new(id: record.id, title: record.title.truncate(TEXT_LENGTH), author: record.author&.truncate(TEXT_LENGTH), isbn: record.isbn)
    RecentRecords.new([ entry, *@entries.reject { it.id == entry.id } ].first(LIMIT).map(&:to_h))
  end

  def each(&)
    @entries.each(&)
  end

  def to_cookie
    @entries.map(&:to_h)
  end

  private
    def entry_from(value)
      return unless value.is_a?(Hash)

      fields = value.symbolize_keys
      Entry.new(id: fields[:id], title: fields[:title], author: fields[:author], isbn: fields[:isbn]) if fields[:id] && fields[:title]
    end
end
