class CitiesController < ApplicationController
  def create
    @city = City.new(city_params)
    @city.user = current_user
    # raise
    if @city.save
      @chat = Chat.create!(title: "*Todo: made dynamic*", city: @city, user: current_user)
      redirect_to chat_path(@chat) # Redirects to new city trip, needs to be a new chat with prompt.
    else
      redirect_to root_path # Need to test this - is this the right location??
    end
  end

  def show
    # raise
    @city = City.find(params[:id])
    @chats = @city.chats.where(user: current_user) # If we want to view the chat on the city page?
  end

  private

  def city_params
    params.require(:city).permit(:name, filters: [])
  end
end
