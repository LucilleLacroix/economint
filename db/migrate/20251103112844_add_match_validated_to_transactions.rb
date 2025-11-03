class AddMatchValidatedToTransactions < ActiveRecord::Migration[7.1]
  def change
    add_column :transactions, :match_validated, :boolean, default: false
  end
end
