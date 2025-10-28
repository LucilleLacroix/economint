# app/services/pdf_transaction_matcher.rb
require 'text'

class PdfTransactionMatcher
  MATCH_WEIGHT_DATE = 0.3
  MATCH_WEIGHT_AMOUNT = 0.4
  MATCH_WEIGHT_DESC = 0.3

  BOOST_IF_CLOSE = 0.75
  DATE_TOLERANCE_DAYS = 1
  AMOUNT_TOLERANCE = 1.0

  attr_reader :transactions, :user

  def initialize(transactions, user)
    @transactions = transactions
    @user = user
  end

  # Normalise les chaînes pour comparaison
  def normalize(str)
    str.to_s.downcase.gsub(/[^a-z0-9\s]/i, '').strip
  end

  # Compare toutes les transactions PDF avec les dépenses et revenus de l'utilisateur
  def match_all
    used_entry_ids = Set.new

    transactions.map do |tx|
      best_match, best_score = find_best_match(tx, used_entry_ids)

      if best_match
        used_entry_ids << best_match.id
      end

      {
        id: tx[:id],
        date: tx[:date],
        description: tx[:description],
        amount: tx[:amount],
        matched_expense: best_match,
        match_score: best_score
      }
    end
  end

  private

  # Trouve la meilleure correspondance pour une transaction, en excluant celles déjà utilisées
  def find_best_match(tx, used_entry_ids)
    best_score = 0.0
    best_entry = nil

    # On combine expenses et revenues
    entries = (user.expenses + user.revenues).reject { |e| used_entry_ids.include?(e.id) }

    entries.each do |entry|
      # Score date avec tolérance
      date_score = if tx[:date] && entry.date
                     (tx[:date] - entry.date).abs <= DATE_TOLERANCE_DAYS ? 1.0 : 0.0
                   else
                     0.0
                   end

      # Score montant avec tolérance
      amount_score = if tx[:amount] && entry.amount
                       (tx[:amount].to_f - entry.amount.to_f).abs <= AMOUNT_TOLERANCE ? 1.0 : 0.0
                     else
                       0.0
                     end

      # Score description ultra inclusif
      tx_desc = normalize(tx[:description])
      entry_desc = normalize(entry.description)

      lev_score = if tx_desc.empty? || entry_desc.empty?
                    0.0
                  else
                    1.0 - (Text::Levenshtein.distance(tx_desc, entry_desc).to_f / [tx_desc.length, entry_desc.length].max)
                  end

      contains_score = (tx_desc.include?(entry_desc) || entry_desc.include?(tx_desc)) ? 1.0 : 0.0
      desc_score = [lev_score, contains_score].max

      # Score pondéré
      total_score = (date_score * MATCH_WEIGHT_DATE) +
                    (amount_score * MATCH_WEIGHT_AMOUNT) +
                    (desc_score * MATCH_WEIGHT_DESC)

      # Boost si date et montant proches
      total_score = [total_score, BOOST_IF_CLOSE].max if date_score == 1.0 && amount_score == 1.0

      if total_score > best_score
        best_score = total_score
        best_entry = entry
      end
    end

    [best_entry, best_score]
  end
end
