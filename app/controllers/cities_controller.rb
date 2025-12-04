class CitiesController < ApplicationController
  def create
    @city = City.new(city_params)
    @city.user = current_user

    if @city.save
      @chat = Chat.create!(title: Chat::DEFAULT_TITLE, city: @city, user: current_user)
      redirect_to chat_path(@chat)
    else
      redirect_to root_path # Need to test this - is this the right location??
    end
  end

  def index
    @cities = current_user.cities.order(created_at: :desc)
  end

  def show
    # raise
    @city = City.find(params[:id])
    @chats = @city.chats.where(user: current_user) # If we want to view the chat on the city page?
  end

  def update
    @city = City.find(params[:id])
    if @city.update(city_params)
      redirect_to @city, notice: "Notes saved successfully!"
    else
      redirect_to @city, alert: "Failed to save notes."
    end
  end

  private

  def city_params
    params.require(:city).permit(:name, :notes, :preferences, :date, filters: [])
  end
end
