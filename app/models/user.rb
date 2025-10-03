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
    default_names = ["Food", "Transport", "Loisirs", "Logement", "Autre"]
    default_colors = [
      "#A3C4F3", "#CDB4DB", "#FFC8DD", "#B28DFF", "#FFB5E8"
    ]

    default_names.each_with_index do |name, i|
      categories.create(name: name, color: default_colors[i])
    end
  end
end
