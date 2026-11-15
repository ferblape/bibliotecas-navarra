class ListsController < ApplicationController
  def show
    @list = List.find_by!(token: params[:id])
    remember_list(@list) unless current_list
  end
end
