require "net/http"

# Google Books, used to find the books a misspelt search meant: its search tolerates
# spelling mistakes. It needs an API key (credentials `google_books.api_key`).
module GoogleBooks
  class Unavailable < StandardError; end

  ERRORS = [ Net::HTTPExceptions, Timeout::Error, SocketError, SystemCallError, OpenSSL::SSL::SSLError, EOFError, JSON::ParserError ].freeze
  PATH = "/books/v1/volumes"
  RESULTS = 10
  TIMEOUT = 5

  mattr_accessor :host, default: "www.googleapis.com"
  mattr_accessor :api_key, default: Rails.application.credentials.dig(:google_books, :api_key)

  extend self

  # Titles and authors of the books that match the query, best match first.
  # Without an API key, no books.
  def search(query)
    return [] unless api_key

    uri = URI::HTTPS.build(host:, path: PATH, query: URI.encode_www_form(q: query, maxResults: RESULTS, key: api_key, fields: "items/volumeInfo(title,authors)"))
    response = Net::HTTP.start(host, use_ssl: true, open_timeout: TIMEOUT, read_timeout: TIMEOUT) { it.request(Net::HTTP::Get.new(uri)) }
    response.value
    texts(response.body)
  rescue *ERRORS => error
    raise Unavailable, error.message
  end

  def texts(json)
    JSON.parse(json).fetch("items", []).flat_map do |item|
      [ item.dig("volumeInfo", "title"), *item.dig("volumeInfo", "authors") ].compact
    end
  end
end
