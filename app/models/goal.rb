class Goal < ApplicationRecord
  belongs_to :user
  validates :category_id, presence: true
  
end
