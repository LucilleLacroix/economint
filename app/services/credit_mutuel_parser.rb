class CreditMutuelParser
  DATE_REGEX   = /\b\d{2}\/\d{2}\/\d{4}\b/
  AMOUNT_REGEX = /\d+(?:[.,]\d{2})/

  # MOTS-CLÉS = CRÉDITS
  CREDIT_KEYWORDS = [
    /impaye/i,             # IMPAYE SEPA → crédit
    /rem(?:ise)? chq/i,    # REM CHQ
    /retro/i,
    /rembourse/i,
    /avoir/i,
    /virement reçu/i,
    /vir\.? reçu/i
  ]

  # MOTS-CLÉS = DÉBITS
  DEBIT_KEYWORDS = [
    /paiement/i,           # CB, PSC
    /prlv/i,               # prélèvement SEPA
    /prelevement/i,
    /cotis/i,
    /prlvt/i
  ]

  def self.parse(text)
    transactions = []
    lines = text.split("\n").map(&:strip)

    lines.each do |line|
      next if line.blank?

      dates = line.scan(DATE_REGEX)
      next unless dates.size >= 2

      date_op     = parse_date(dates[0])
      date_valeur = parse_date(dates[1])

      raw_amount = line.scan(AMOUNT_REGEX).last
      next unless raw_amount

      amount = raw_amount.tr(",", ".").to_f

      description = extract_description(line, dates, raw_amount)

      # 1️⃣ MOTS CLÉS CRÉDIT
      if CREDIT_KEYWORDS.any? { |k| description =~ k }
        amount = amount.abs
        type   = "revenue"

      # 2️⃣ MOTS CLÉS DÉBIT
      elsif DEBIT_KEYWORDS.any? { |k| description =~ k }
        amount = -amount.abs
        type   = "expense"

      # 3️⃣ PAR DÉFAUT = DÉBIT (Crédit Mutuel règle générale)
      else
        amount = -amount.abs
        type = "expense"
      end

      transactions << {
        date: date_valeur || date_op,
        description: description,
        amount: amount,
        type: type
      }
    end

    transactions
  end

  def self.extract_description(line, dates, amount)
    line
      .sub(dates[0], "")
      .sub(dates[1], "")
      .sub(amount, "")
      .strip
  end

  def self.parse_date(str)
    Date.strptime(str, "%d/%m/%Y") rescue nil
  end
end
