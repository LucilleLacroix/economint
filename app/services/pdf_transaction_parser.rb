class PdfTransactionParser
  DATE_REGEX = /\d{2}\.\d{2}/
  AMOUNT_REGEX = /-?\d+(?:[.,]\d{2})?/

  def self.parse(text)
    transactions = []
    lines = text.split("\n").map(&:strip)

    lines.each_with_index do |line, idx|
      next if line.blank?
      # Repérer les lignes qui commencent par deux dates
      dates = line.scan(DATE_REGEX)
      next unless dates.size >= 2

      date_valeur = parse_date(dates[1])
      description = line.sub(/^#{dates[0]}\s+#{dates[1]}/, "").strip

      # Extraire le dernier montant dans la ligne
      amount_match = line.scan(AMOUNT_REGEX).last
      next unless amount_match

      amount = amount_match.gsub(",", ".").to_f

      # Si la description contient "Virement" ou "Crédit", considérer montant positif
      if description =~ /Virement|Crédit/i
        amount = amount.abs
      else
        amount = -amount
      end

      transactions << {
        date: date_valeur,
        description: description,
        amount: amount
      }
    end

    transactions
  end

  def self.parse_date(str)
    day, month = str.split(".").map(&:to_i)
    Date.new(Date.today.year, month, day) rescue nil
  end
end
