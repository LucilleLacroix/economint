class ChangeTransactionMatchedExpenseToPolymorphic < ActiveRecord::Migration[7.1]
   def change
    # Supprime l’ancienne clé étrangère et colonne si elles existent
    if column_exists?(:transactions, :matched_expense_id)
      remove_foreign_key :transactions, column: :matched_expense_id rescue nil
      remove_column :transactions, :matched_expense_id, :bigint
    end

    # ✅ N’ajoute les colonnes polymorphiques que si elles n’existent pas déjà
    unless column_exists?(:transactions, :matchable_id)
      add_reference :transactions, :matchable, polymorphic: true, index: true
    end
  end
end
