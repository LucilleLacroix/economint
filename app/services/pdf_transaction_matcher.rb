class PdfTransactionMatcher
  MATCH_WEIGHT_DATE = 0.3
  MATCH_WEIGHT_AMOUNT = 0.4
  MATCH_WEIGHT_DESC = 0.3

  BOOST_IF_CLOSE = 0.75
  DATE_TOLERANCE_DAYS = 1
  AMOUNT_TOLERANCE = 1.0

  attr_reader :transactions, :user, :start_date, :end_date

  def initialize(transactions, user, start_date: nil, end_date: nil)
    @transactions = transactions
    @user = user
    @start_date = start_date
    @end_date = end_date
  end

  def normalize(str)
    str.to_s.downcase.gsub(/[^a-z0-9\s]/i, '').strip
  end

  def match_all
    used_entry_ids = Set.new

    transactions.map do |tx|
      best_match, best_score = find_best_match(tx, used_entry_ids)

      {
        id: tx[:id],
        date: tx[:date],
        description: tx[:description],
        amount: tx[:amount],
        type: tx[:type],
        matchable: best_match,
        matchable_type: best_match&.class&.name,
        matchable_id: best_match&.id,
        match_score: best_score
      }
    end
  end

  private

  def find_best_match(tx, used_entry_ids)
    best_score = 0.0
    best_entry = nil

    # 🔹 Sélectionner le type de transaction
    entries = case tx[:type]&.downcase
              when 'expense' then user.expenses
              when 'revenue' then user.revenues
              else user.expenses.or(user.revenues)
              end

    # 🔹 Filtrer selon la période du relevé si start_date/end_date fournis
    if start_date && end_date
      entries = entries.where(date: start_date..end_date)
    end

    # 🔹 Exclure les transactions déjà utilisées
    entries = entries.reject { |e| used_entry_ids.include?([e.class.name, e.id]) }

    entries.each do |entry|
      # Score date
      date_score = (tx[:date] && entry.date && (tx[:date] - entry.date).abs <= DATE_TOLERANCE_DAYS) ? 1.0 : 0.0

      # Score montant
      amount_score = (tx[:amount] && entry.amount && (tx[:amount].to_f - entry.amount.to_f).abs <= AMOUNT_TOLERANCE) ? 1.0 : 0.0

      # Score description
      tx_desc = normalize(tx[:description])
      entry_desc = normalize(entry.description)

      lev_score = if tx_desc.empty? || entry_desc.empty?
                    0.0
                  else
                    1.0 - (Text::Levenshtein.distance(tx_desc, entry_desc).to_f / [tx_desc.length, entry_desc.length].max)
                  end

      contains_score = (tx_desc.include?(entry_desc) || entry_desc.include?(tx_desc)) ? 1.0 : 0.0
      desc_score = [lev_score, contains_score].max

      # Score global
      total_score = (date_score * MATCH_WEIGHT_DATE) +
                    (amount_score * MATCH_WEIGHT_AMOUNT) +
                    (desc_score * MATCH_WEIGHT_DESC)

      total_score = [total_score, BOOST_IF_CLOSE].max if date_score == 1.0 && amount_score == 1.0

      if total_score > best_score
        best_score = total_score
        best_entry = entry
      end
    end

    # 🔹 Marquer comme utilisé
    used_entry_ids << [best_entry.class.name, best_entry.id] if best_entry

    [best_entry, best_score]
  end
end
