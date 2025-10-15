class CreateBudgets < ActiveRecord::Migration[7.1]
  def change
    create_table :budgets do |t|
      t.references :user, null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true
      t.date :start_date
      t.date :end_date
      t.decimal :pessimistic_amount
      t.decimal :realistic_amount
      t.decimal :optimistic_amount
      t.decimal :actual_amount

      t.timestamps
    end
  end
end
