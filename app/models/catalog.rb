# The catalog of the Bibliotecas Públicas de Navarra, read live from their OPAC.
# Answers are cached for a while to keep the load on the OPAC low.
module Catalog
  class Unavailable < StandardError; end

  OPAC_ERRORS = [ Net::HTTPExceptions, Timeout::Error, SocketError, SystemCallError, OpenSSL::SSL::SSLError, EOFError ].freeze
  SEARCH = { ACC: 131, START: 1, FORM: 1, xindbt: "", xmismo: "on", FORM_DIGITAL: 9, xsface: "on" }.freeze

  extend self

  def search(query, library: nil, page: 1)
    cached [ "search", query, library, page ], expires_in: 10.minutes do
      session = Opac::Session.open(ACC: 101)
      session.post(ACC: 101, xindbt: "", subcat: library) if library
      html = session.post(**SEARCH, xsqf01: query)
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
