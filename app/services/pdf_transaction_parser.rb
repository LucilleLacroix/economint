# app/services/pdf_transaction_parser.rb
class PdfTransactionParser
  def self.parse_table(table_rows)
    transactions = []

    table_rows.each do |row|
      # Adapter selon l'ordre des colonnes de ton PDF
      date_str    = row[0]&.strip
      description = row[1]&.strip
      amount_str  = row[2]&.strip

      next unless date_str && amount_str

      date   = PdfReaderService.parse_date(date_str)
      amount = PdfReaderService.parse_amount(amount_str)
      type   = amount >= 0 ? 'revenue' : 'expense'

      transactions << {
        date: date,
        description: description,
        amount: amount,
        type: type
      }
    end

    transactions
  end
end
