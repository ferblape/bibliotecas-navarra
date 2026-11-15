class SearchesController < ApplicationController
  before_action :remember_library

  def index
    @libraries = Catalog.libraries
    if query
      @results = Catalog.search(query, field:, library: library&.code, page:)
    else
      @recent_records = recent_records
    end
  end

  private
    def remember_library
      cookies.permanent[:library] = params[:library] if params.key?(:library)
    end

    def query
      params[:q].presence&.squish
    end

    def field
      params[:field].presence_in(Catalog::FIELDS.keys.map(&:to_s))&.to_sym || :any
    end

    def page
      [ params[:page].to_i, 1 ].max
    end
end
