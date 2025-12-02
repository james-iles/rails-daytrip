class ChatsController < ApplicationController

  def create
  @city = City.find(params[:city_id])

  @chat = Chat.new(title: "Untitled")
  @chat.city = @city
  @chat.user = current_user

    if @chat.save
      redirect_to chat_path(@chat)
    else
      @chats = @city.chats.where(user: current_user)
      render "cities/show"
    end
  end

  def show
    @chat = current_user.chats.find(params[:id])
    @message = Message.new
  end
end
