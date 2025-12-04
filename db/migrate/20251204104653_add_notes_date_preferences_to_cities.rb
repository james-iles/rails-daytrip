class AddNotesDatePreferencesToCities < ActiveRecord::Migration[7.1]
  def change
    add_column :cities, :notes, :text
    add_column :cities, :date, :datetime
    add_column :cities, :preferences, :text
  end
end
