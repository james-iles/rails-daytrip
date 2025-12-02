class CitiesController < ApplicationController
  def create
    # raise
    @city = City.new(city_params)
    @user_id = current_user.id
    @city.user_id = @user_id
    # raise
    if @city.save
      redirect_to city_path(@city) # Redirects to new city trip, needs to be a new chat with prompt.
    else
      # What? We don't use a new city action...
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
