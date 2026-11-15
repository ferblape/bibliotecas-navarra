require "net/http"

module Opac
  # A browsing session in the OPAC. The OPAC keeps state (chosen library, last search)
  # on the server, tied to a token in the URL path and to the GN/GNW cookies.
  class Session
    class Refused < StandardError; end

    ENTRY_PATH = "/opac/abnetcl.exe"
    ENCODING = Encoding::ISO_8859_1
    USER_AGENT = "BibliotecasNavarra/1.0 (unofficial catalog search)"
    TIMEOUT = 10

    mattr_accessor :host, default: "www.navarra.es"

    attr_reader :path, :page

    # Opens a session from an entry URL (for example `ACC: 101` for the home page or
    # `TITN: id` for a record). The OPAC answers with a meta refresh to the session URL.
    def self.open(params)
      new(params)
    end

    # The entry page answers with a meta refresh to the session URL. Without it, the
    # OPAC refused to open a session (for example, an "Error 205" page when it is busy).
    def self.session_url(entry_page)
      entry_page[/URL=([^"]+)"/, 1] or raise Refused, "The OPAC did not open a session"
    end

    def self.entry_url(params)
      "https://#{host}#{ENTRY_PATH}?#{URI.encode_www_form(params)}"
    end

    def initialize(params)
      @cookies = {}
      session_url = self.class.session_url(request(Net::HTTP::Get.new("#{ENTRY_PATH}?#{form_data(params)}")))
      @path = URI(session_url).path
      @page = request Net::HTTP::Get.new(session_url)
    end

    def get(params)
      request Net::HTTP::Get.new("#{path}?#{form_data(params)}")
    end

    def post(params)
      request Net::HTTP::Post.new(path).tap { it.body = form_data(params) }
    end

    private
      def request(request)
        request["User-Agent"] = USER_AGENT
        request["Cookie"] = @cookies.map { |name, value| "#{name}=#{value}" }.join("; ")
        response = http.request(request)
        response.value
        store_cookies(response)
        response.body.force_encoding(ENCODING).encode(Encoding::UTF_8)
      end

      def http
        @http ||= Net::HTTP.start(host, use_ssl: true, open_timeout: TIMEOUT, read_timeout: TIMEOUT)
      end

      def store_cookies(response)
        response.get_fields("Set-Cookie")&.each do |cookie|
          name, value = cookie.split(";").first.split("=", 2)
          @cookies[name] = value
        end
      end

      # Characters that do not exist in ISO-8859-1 cannot reach the OPAC, so they are dropped.
      def form_data(params)
        URI.encode_www_form(params.transform_values { it.to_s.encode(ENCODING, invalid: :replace, undef: :replace, replace: "") })
      end
  end
end
