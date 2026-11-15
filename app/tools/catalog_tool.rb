# A tool that answers from the catalog of the Bibliotecas Públicas de Navarra. Subclasses
# implement `answer`. The answer goes both as structured content and as JSON text, for
# clients that only read text.
class CatalogTool < MCP::Tool
  UNAVAILABLE = "The catalog of the Bibliotecas Públicas de Navarra is not available right now. Try again in a few minutes."

  class << self
    def call(server_context:, **arguments)
      answer(server_context:, **arguments)
    rescue Catalog::Unavailable
      MCP::Tool::Response.new([ { type: "text", text: UNAVAILABLE } ], error: true)
    end

    private
      def respond(data)
        MCP::Tool::Response.new([ { type: "text", text: data.to_json } ], structured_content: data)
      end
  end
end
