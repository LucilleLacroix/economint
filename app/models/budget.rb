class Budget < ApplicationRecord
  belongs_to :user
  belongs_to :category

  validates :start_date, :end_date, presence: true

  def period
    "#{start_date} → #{end_date}"
  end

  def update_actual_amount!
    total = user.expenses
                 .where(category: category)
                 .where(date: start_date..end_date)
                 .sum(:amount)
    update!(actual_amount: total)
  end
end
