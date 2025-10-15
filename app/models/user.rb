class User < ApplicationRecord
  has_many :categories
  has_many :checklists
  has_many :expenses
  has_many :goals
  has_many :predictions
  has_many :reconciliations
  has_many :revenues
  has_many :budgets, dependent: :destroy
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  after_create :create_default_categories

  def create_default_categories
    expense_names = ["Transport", "Loisir", "Logement", "Alimentaire"]
    revenue_names = ["Salaire", "Bonus", "Freelance", "Cadeaux"]

    expense_colors = ["#A3C4F3", "#CDB4DB", "#FFC8DD", "#B28DFF"]
    revenue_colors = ["#FFB5E8", "#FFDAC1", "#E2F0CB", "#B5EAEA"]

    expense_names.each_with_index do |name, i|
      categories.create(name: name, category_type: "expense", color: expense_colors[i])
    end

    revenue_names.each_with_index do |name, i|
      categories.create(name: name, category_type: "revenue", color: revenue_colors[i])
    end
  end

  def expense_categories
    categories.for_expenses
  end

  def revenue_categories
    categories.for_revenues
  end
end
