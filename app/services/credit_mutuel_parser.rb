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

      # On enlève les dates pour travailler sur "le reste"
      line_without_dates = line.sub(dates[0], "").sub(dates[1], "").strip
      tokens = line_without_dates.split(/\s+/)

      # Tous les montants présents sur la ligne (débit et crédit)
      amount_tokens = tokens.select { |t| t =~ AMOUNT_REGEX }
      next if amount_tokens.empty?

      # On suppose : ... LIBELLE ... [DEBIT] [CREDIT]
      debit_raw  = nil
      credit_raw = nil

      if amount_tokens.size >= 2
        # 5 colonnes : on prend l’avant-dernier comme débit, le dernier comme crédit
        debit_raw  = amount_tokens[-2]
        credit_raw = amount_tokens[-1]
      else
        # 1 seul montant sur la ligne : on le traitera avec les mots-clés ensuite
        debit_raw = amount_tokens.first
      end

      # Description = tout ce qui est avant les montants
      description_tokens = []
      tokens.each do |t|
        break if amount_tokens.include?(t)
        description_tokens << t
      end
      description = description_tokens.join(" ").strip

      amount = nil
      type   = nil

      # 1️⃣ PRIORITÉ AUX COLONNES DÉBIT / CRÉDIT
      if credit_raw && !zero_amount?(credit_raw)
        amount = normalize_amount(credit_raw)
        type   = "revenue"
      elsif debit_raw
        amount = -normalize_amount(debit_raw)
        type   = "expense"
      end

      # 2️⃣ SI BESOIN, FALLBACK SUR LA LOGIQUE MOTS-CLÉS
      if amount.nil?
        raw_amount = amount_tokens.last
        amount     = normalize_amount(raw_amount)

        # 1️⃣ mots-clés crédit
        if CREDIT_KEYWORDS.any? { |k| description =~ k }
          amount = amount.abs
          type   = "revenue"

        # 2️⃣ mots-clés débit
        elsif DEBIT_KEYWORDS.any? { |k| description =~ k }
          amount = -amount.abs
          type   = "expense"

        # 3️⃣ par défaut = débit
        else
          amount = -amount.abs
          type   = "expense"
        end
      end

      transactions << {
        date:        date_valeur || date_op,
        description: description,
        amount:      amount,
        type:        type
      }
    end

    transactions
  end

  def self.normalize_amount(str)
    # enlève les espaces insécables éventuels, remplace virgule par point
    str.tr(" ", "").tr(",", ".").to_f
  end

  def self.zero_amount?(str)
    normalize_amount(str).zero?
  end

  # Gardé au cas où tu l’utilises ailleurs
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
