# app/services/reconciliation_matcher_service.rb
class ReconciliationMatcherService
  def self.recalculate_for_user(user)
    user.reconciliations.includes(:transactions).each do |reconciliation|
      # Exclure les transactions déjà validées
      exclude_entries = reconciliation.transactions
                                      .where(match_validated: true)
                                      .map { |t| [t.matchable_type, t.matchable_id] }
                                      .compact

      remaining_transactions = reconciliation.transactions.where(match_validated: false)

      matcher = PdfTransactionMatcher.new(
        remaining_transactions.map { |t|
          {
            id: t.id,
            date: t.date,
            description: t.description,
            amount: t.amount,
            type: t.amount < 0 ? 'expense' : 'revenue'
          }
        },
        user,
        start_date: reconciliation.transactions.minimum(:date),
        end_date: reconciliation.transactions.maximum(:date),
        exclude_entries: exclude_entries
      )

      new_matches = matcher.match_all

      new_matches.each do |m|
        tx_to_update = reconciliation.transactions.find(m[:id])
        tx_to_update.update(
          matchable_id: m[:matchable_id],
          matchable_type: m[:matchable_type],
          match_score: m[:match_score]
        )
      end
    end
  end
end
