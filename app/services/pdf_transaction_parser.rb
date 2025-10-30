class PdfTransactionParser
  DATE_REGEX = /\d{2}\.\d{2}/
  AMOUNT_REGEX = /-?\d+(?:[.,]\d{2})?/

  def self.parse(text)
    transactions = []
    lines = text.split("\n").map(&:strip)

    lines.each_with_index do |line, idx|
      next if line.blank?

      # Repérer les deux dates dans la ligne
      dates = line.scan(DATE_REGEX)
      next unless dates.size >= 2

      date_valeur = parse_date(dates[1])

      # Nettoyer la description
      description = line.sub(/^#{dates[0]}\s+#{dates[1]}/, "").strip

      # Extraire le dernier montant
      amount_match = line.scan(AMOUNT_REGEX).last
      next unless amount_match

      amount = amount_match.gsub(",", ".").to_f

      # Déterminer la colonne via mots-clés
      is_credit = line =~ /\bCrédit\b/i
      is_debit = line =~ /\bDébit\b/i

      if description =~ /Virement|Avoir|Ristourne/i || is_credit
        # Crédit ou virement → revenu
        amount = amount.abs
        type = "revenue"
      else
        # Par défaut → dépense
        amount = -amount.abs
        type = "expense"
      end

      transactions << {
        date: date_valeur,
        description: description,
        amount: amount,
        type: type
      }
    end

    transactions
  end

  def self.parse_date(str)
    day, month = str.split(".").map(&:to_i)
    Date.new(Date.today.year, month, day) rescue nil
  end
end
