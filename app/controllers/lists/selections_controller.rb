# Choosing, or forgetting, the list this browser saves bookmarks in.
class Lists::SelectionsController < ApplicationController
  def create
    list = List.find_by!(token: params[:list_id])
    remember_list(list)
    redirect_to list
  end

  def destroy
    cookies.delete(:list)
    redirect_to root_path, notice: "Este navegador ya no recuerda la lista. Puedes volver a ella con su dirección."
  end
end
