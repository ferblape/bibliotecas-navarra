class LibrariesController < ApplicationController
  def index
    @public_libraries, @specialized_libraries = LibraryDirectory.all.partition(&:public?)
  end
end
