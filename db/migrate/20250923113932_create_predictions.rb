class CreatePredictions < ActiveRecord::Migration[7.1]
  def change
    create_table :predictions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :scenario_name
      t.jsonb :forecast_data

      t.timestamps
    end
  end
end
