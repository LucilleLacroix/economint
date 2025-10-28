class AddNameToReconciliations < ActiveRecord::Migration[7.1]
  def change
    add_column :reconciliations, :name, :string
  end
end
