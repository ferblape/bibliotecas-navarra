require "net/http"

# The geocoder of the Spanish Government (https://www.cartociudad.es), free and without
# keys. It finds a street and number, a street or a town, but not addresses with postal
# codes, "s/n" or the Basque name of the town after a slash, so those are left out. Quotes
# make it fail with a server error.
module CartoCiudad
  URL = "https://www.cartociudad.es/geocoder/api/geocoder/find"
  PAUSE = 0.3

  extend self

  # Latitude and longitude of an address in Navarra, or nil when the geocoder cannot find it.
  def coordinates(address)
    queries(address).lazy.filter_map { point(fetch(it)) }.first
  end

  # From the most precise to the least: street and number, street, town.
  def queries(address)
    parts = address.delete(%(")).split(",").map(&:strip)
    town = parts.last.sub(/\A\d{5}\s*/, "").split(%r{\s*/\s*|\s+-\s+}).first.sub(/\s*\(.*\)/, "").strip
    street = parts.first.sub(%r{\s*\bs/n\z}i, "").sub(/\s*\(.*\)/, "").strip
    number = parts[1][/\A\d+/] if parts.size > 2

    [ ("#{street} #{number}, #{town}" if number), "#{street}, #{town}", town ].compact.uniq
  end

  def point(json)
    place = JSON.parse(json) rescue nil
    [ place["lat"].round(5), place["lng"].round(5) ] if place.is_a?(Hash) && place["province"] == "Navarra" && place["lat"]
  end

  private
    def fetch(query)
      sleep PAUSE
      uri = URI(URL).tap { it.query = URI.encode_www_form(q: query) }
      response = Net::HTTP.get_response(uri)
      response.value
      response.body
    end
end
