class Category < ApplicationRecord
  belongs_to :user
  has_many :expenses, dependent: :destroy
  has_many :revenues
  has_many :budgets, dependent: :destroy


  validates :color, presence: true
  validates :name, presence: true
  validates :category_type, inclusion: {in: %[expense revenue]}
  scope :for_expenses, -> { where(category_type: "expense") }
  scope :for_revenues, -> { where(category_type: "revenue") }

end
