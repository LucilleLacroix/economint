# app/services/pdf_reader_service.rb
require 'tabula'
require_relative 'pdf_transaction_parser'

class PdfReaderService
  # Extrait les transactions d'un PDF bancaire
  def self.extract_transactions(file_path)
    # 🔹 Extraire tous les tableaux du PDF
    tables = Tabula.extract(file_path, output_format: :json)

    # 🔹 Parcourir tous les tableaux et extraire les transactions
    all_transactions = tables.flat_map do |table|
      PdfTransactionParser.parse_table(table['data'])
    end

    all_transactions
  rescue => e
    Rails.logger.error("Erreur lecture PDF avec Tabula : #{e.message}")
    []
  end

  # Méthode pour parser une date depuis une cellule
  def self.parse_date(str)
    return nil unless str

    str = str.gsub('/', '.').strip
    parts = str.split('.').map(&:to_i)

    case parts.size
    when 2
      Date.new(Date.today.year, parts[1], parts[0]) rescue nil
    when 3
      Date.new(parts[2], parts[1], parts[0]) rescue nil
    else
      nil
    end
  end

  # Méthode pour parser un montant depuis une cellule
  def self.parse_amount(str)
    return 0.0 unless str

    clean = str.gsub(/\s/, '').gsub(',', '.')
    clean.to_f
  rescue
    0.0
  end
end
