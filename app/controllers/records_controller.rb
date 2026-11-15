class RecordsController < ApplicationController
  def show
    @record = Catalog.record(params[:id])
  end

  private
    # After saving a bookmark the referer is the record itself, which is no way back.
    def back_url
      referer = request.referer.presence
      referer && URI(referer).path != request.path ? referer : root_path
    end
    helper_method :back_url
end
