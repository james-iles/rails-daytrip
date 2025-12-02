class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: :home

  def home
    @city = City.new

    @filter_options = [
              "Coffee",
              "Breakfast",
              "Gyms",
              "Brunch",
              "Museums",
              "Lunch",
              "Quick Bites",
              "Nightlife",
              "Restaurants",
              "Nature",
              "Landmarks",
              "Shopping"
            ]
  end
end
