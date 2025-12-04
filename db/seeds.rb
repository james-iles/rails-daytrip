# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# db/seeds.rb

filter_options = [
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

city_names = [
  "Barcelona",
  "London",
  "Paris",
  "Berlin",
  "Rome",
  "Amsterdam",
  "Lisbon",
  "New York",
  "Tokyo",
  "Sydney"
]

users = User.create!([
  { email: "test1@test.com", password: "password" },
  { email: "test2@test.com", password: "password" },
  { email: "test3@test.com", password: "password" },
  { email: "test4@test.com", password: "password" },
])

city_names.each do |city|
  City.create!(
    name: city,
    filters: filter_options.sample(rand(2..4)),
    user: users.sample
  )
end

puts "Seeded #{city_names.size} cities..."
