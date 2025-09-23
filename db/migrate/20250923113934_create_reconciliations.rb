class CreateReconciliations < ActiveRecord::Migration[7.1]
  def change
    create_table :reconciliations do |t|
      t.references :user, null: false, foreign_key: true
      t.string :bank_file_name
      t.string :status
      t.jsonb :summary

      t.timestamps
    end
  end
end
