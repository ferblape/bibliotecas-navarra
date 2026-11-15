require "net/http"

# The catalog of the Bibliotecas Públicas de Navarra, read live from their OPAC.
# Answers are cached for a while to keep the load on the OPAC low.
module Catalog
  class Unavailable < StandardError; end

  OPAC_ERRORS = [
    Opac::Session::Refused, Opac::UnexpectedPage,
    Net::HTTPExceptions, Timeout::Error, SocketError, SystemCallError, OpenSSL::SSL::SSLError, EOFError
  ].freeze
  ALL_LIBRARIES = "/"
  SEARCH = { ACC: 131, START: 1, FORM: 2, xsnf12: 0 }.freeze

  # Fields of the OPAC advanced search form. The OPAC combines several fields unreliably
  # when a library is chosen, so a search uses one field at a time.
  FIELDS = { any: :xsqf01, title: :xsqf12, author: :xsqf03, subject: :xsqf05 }.freeze

  extend self

  def search(query, field: :any, library: nil, page: 1)
    cached [ "search", query, field, library, page ], expires_in: 10.minutes do
      session = Opac::Session.open(ACC: 101)
      html = session.post(**SEARCH, FIELDS.fetch(field) => query, subcat: library || ALL_LIBRARIES)
      html = session.get(ACC: 161, DOC: (page - 1) * Opac::Results::PER_PAGE + 1) if page > 1
      Opac::ResultsPage.new(html, page:).results
    end
  end

  def record(id)
    cached [ "record", id ], expires_in: 10.minutes do
      Opac::RecordPage.new(Opac::Session.open(TITN: id).page).record
    end
  end

  def libraries
    cached [ "libraries" ], expires_in: 1.day do
      Opac::LibrariesPage.new(Opac::Session.open(ACC: 101).page).libraries
    end
  end

  private
    def cached(key, expires_in:, &)
      Rails.cache.fetch([ "catalog", *key ], expires_in:, &)
    rescue *OPAC_ERRORS => error
      raise Unavailable, error.message
    end
end
