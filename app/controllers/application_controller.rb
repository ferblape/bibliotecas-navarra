class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  # Every search or record not in the cache costs a session in the OPAC.
  rate_limit to: 30, within: 1.minute, with: -> { render "shared/too_many_requests", status: :too_many_requests }

  rescue_from Catalog::Unavailable do
    render "shared/unavailable", status: :service_unavailable
  end

  private
    # The library chosen in the search form, remembered across visits.
    def library
      @library ||= Catalog.libraries.find { it.code == cookies[:library] } if cookies[:library].present?
    end
    helper_method :library
end
