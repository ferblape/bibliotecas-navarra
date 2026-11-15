# Search engines, AI crawlers and link previews get a 403 instead of the page:
# each page they fetch can cost a session in the OPAC, and the service should
# stay out of indexes. Static files such as robots.txt are served before this.
class BlockCrawlers
  CRAWLER = /bot\b|crawl|spider|slurp|facebookexternalhit|meta-externalagent|ia_archiver/i

  def initialize(app)
    @app = app
  end

  def call(env)
    if env["HTTP_USER_AGENT"].to_s.match?(CRAWLER)
      [ 403, { "content-type" => "text/plain" }, [ "Forbidden" ] ]
    else
      @app.call(env)
    end
  end
end
