class CreateTransactions < ActiveRecord::Migration[7.1]
  def change
    create_table :transactions do |t|
      t.references :reconciliation, null: false, foreign_key: true
      t.date :date
      t.string :description
      t.decimal :amount
      t.references :matched_expense, null: false, foreign_key: { to_table: :expenses }
      t.decimal :match_score

      t.timestamps
    end
  end
end
