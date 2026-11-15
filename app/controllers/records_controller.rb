class RecordsController < ApplicationController
  def show
    @record = Catalog.record(params[:id])
  end
end
