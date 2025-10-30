class ReconciliationUpdater
  def self.update_matches_for_reconciliation(reconciliation)
    user = reconciliation.user

    # Construire les données brutes depuis les transactions existantes
    raw_transactions = reconciliation.transactions.map do |tx|
      { id: tx.id, date: tx.date, description: tx.description, amount: tx.amount }
    end

    # Calculer les nouveaux matches
    matched = PdfTransactionMatcher.new(raw_transactions, user).match_all

    # Mettre à jour les transactions existantes
    matched.each do |m|
      tx = reconciliation.transactions.find(m[:id])
      tx.update(matchable: m[:matchable], match_score: m[:match_score])
    end
  end
end

