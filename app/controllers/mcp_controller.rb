# Answers Model Context Protocol requests from AI agents. Each request stands on its own
# (no MCP session is kept), so any process can answer it.
class McpController < ActionController::API
  TOOLS = [ ListLibrariesTool, SearchCatalogTool, GetRecordTool ].freeze

  # Stricter than the web: agents fire requests in bursts, and all claude.ai users reach us from
  # a few shared addresses, so the limit of all agents together is what spares the OPAC.
  rate_limit to: 10, within: 1.minute, name: "agent", with: -> { too_many_requests }
  rate_limit to: 60, within: 1.minute, name: "all", by: -> { "all" }, with: -> { too_many_requests }

  def create
    status, headers, body = transport.handle_request(request)
    response.headers.merge!(headers)
    self.status = status
    self.response_body = body
  end

  private
    def too_many_requests
      render status: :too_many_requests,
        json: { jsonrpc: "2.0", id: nil, error: { code: -32000, message: "Too many requests. Wait a minute before asking the catalog again." } }
    end

    def transport
      MCP::Server::Transports::StreamableHTTPTransport.new(server, stateless: true, enable_json_response: true,
        serve_subscriptions_listen: false,
        # Guards local servers against DNS rebinding. This one is public, read-only and keeps no
        # cookies or credentials, so there is nothing a rebound page could reach that it cannot already.
        dns_rebinding_protection: false)
    end

    def server
      MCP::Server.new(name: "bibliotecas-navarra", title: "Bibliotecas Públicas de Navarra", version: "1.0.0", tools: TOOLS,
        server_context: { base_url: request.base_url })
    end
end
