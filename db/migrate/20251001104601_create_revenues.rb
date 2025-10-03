class CreateRevenues < ActiveRecord::Migration[7.1]
  def change
    create_table :revenues do |t|
      t.references :user, null: false, foreign_key: true
      t.decimal :amount
      t.string :category
      t.text :description
      t.date :date

      t.timestamps
    end
  end
end
