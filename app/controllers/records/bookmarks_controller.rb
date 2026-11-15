class Records::BookmarksController < ApplicationController
  def create
    unless current_list
      remember_list(List.create!)
      flash[:new_list] = true
    end
    current_list.bookmark(Catalog.record(params[:record_id]))
    redirect_to record_path(params[:record_id])
  end

  def destroy
    current_list&.bookmarks&.find_by(record_id: params[:record_id])&.destroy
    redirect_back_or_to record_path(params[:record_id])
  end
end
