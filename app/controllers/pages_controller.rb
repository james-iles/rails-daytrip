class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: :home

  def home
    @city = City.new
    @filter_options = [
              "Coffee",
              "Breakfast",
              "Brunch",
              "Lunch",
              "Quick Bites",
              "Restaurants",
              "Bakeries",
              "Bars",
              "Gyms",
              "Yoga Studios",
              "Hiking",
              "Parks",
              "Nature",
              "Beaches",
              "Museums",
              "Art Galleries",
              "Landmarks",
              "Shopping",
              "Markets",
              "Nightlife",
              "Live Music",
              "Unique Experiences",
            ]
  end
end
