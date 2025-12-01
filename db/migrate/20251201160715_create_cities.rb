class CreateCities < ActiveRecord::Migration[7.1]
  def change
    create_table :cities do |t|
      t.string :name
      t.text :filters
      t.text :itinerary

      t.timestamps
    end
  end
end
