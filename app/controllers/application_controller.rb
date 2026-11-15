class ApplicationController < ActionController::Base
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

    # The bookmarks list of this browser. Knowing its URL is enough to use it.
    def current_list
      @current_list ||= List.find_by(token: cookies[:list]) if cookies[:list].present?
    end
    helper_method :current_list

    def recent_records
      RecentRecords.new(cookies.signed[:recent_records])
    end

    def remember_list(list)
      cookies.permanent[:list] = { value: list.token, httponly: true }
      @current_list = list
    end
end
