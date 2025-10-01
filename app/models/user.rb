class User < ApplicationRecord
  has_many :categories
  has_many :checklists
  has_many :expenses
  has_many :goals
  has_many :predictions
  has_many :reconciliations

  # Devise modules
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
end
