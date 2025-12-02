class CitiesController < ApplicationController
  def create
  end

  def show
    # raise
    @city = City.find(params[:id])
    @chats = @city.chats.where(user: current_user) # If we want to view the chat on the city page?
  end
end
