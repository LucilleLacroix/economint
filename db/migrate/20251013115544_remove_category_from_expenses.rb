class RemoveCategoryFromExpenses < ActiveRecord::Migration[7.1]
  def change
    remove_column :expenses, :category, :string
  end
end
