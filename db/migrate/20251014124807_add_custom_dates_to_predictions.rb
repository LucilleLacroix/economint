class AddCustomDatesToPredictions < ActiveRecord::Migration[7.1]
  def change
    add_column :predictions, :base_start_date, :date
    add_column :predictions, :base_end_date, :date
    add_column :predictions, :forecast_start_date, :date
    add_column :predictions, :forecast_end_date, :date
  end
end
