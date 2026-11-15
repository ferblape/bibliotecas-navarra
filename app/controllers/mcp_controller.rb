# Answers Model Context Protocol requests from AI agents. Each request stands on its own
# (no MCP session is kept), so any process can answer it.
class McpController < ActionController::API
  TOOLS = [ ListLibrariesTool ].freeze

  def create
    status, headers, body = transport.handle_request(request)
    response.headers.merge!(headers)
    self.status = status
    self.response_body = body
  end

  private
    def transport
      MCP::Server::Transports::StreamableHTTPTransport.new(server, stateless: true, enable_json_response: true,
        serve_subscriptions_listen: false,
        # Guards local servers against DNS rebinding. This one is public, read-only and keeps no
        # cookies or credentials, so there is nothing a rebound page could reach that it cannot already.
        dns_rebinding_protection: false)
    end

    def server
      MCP::Server.new(name: "bibliotecas-navarra", title: "Bibliotecas Públicas de Navarra", version: "1.0.0", tools: TOOLS)
    end
end
