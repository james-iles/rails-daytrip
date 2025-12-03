class ChangeFiltersToArrayInCities < ActiveRecord::Migration[7.0]
def change
    change_column :cities, :filters, :text, default: "[]"
  end
end
