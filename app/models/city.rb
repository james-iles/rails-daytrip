class City < ApplicationRecord
  belongs_to :user
  has_many :chats, dependent: :destroy

  serialize :filters, type: Array, coder: YAML
  validates :name, presence: true

#   FILTER_OPTIONS = [
#   "Culture & Museums",
#   "Coffee Shops",
#   "Shopping",
#   "Nightlife",
#   "Food & Dining",
#   "Nature & Parks",
#   "History",
#   "Architecture",
#   "Local Markets",
#   "Photography",
#   "Budget-Friendly",
#   "Luxury Experiences"
# ]
end
