class User < ApplicationRecord
  has_many :categories
  has_many :checklists
  has_many :expenses
  has_many :goals
  has_many :predictions
  has_many :reconciliations
  has_many :revenues

  # Devise modules
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  after_create :create_default_categories
  private

  def create_default_categories
    default_categories = [
      "Alimentation",
      "Logement",
      "Transport",
      "Loisirs",
      "Santé"
    ]

    default_categories.each do |name|
      categories.create!(name: name) 
    end
  end
end
