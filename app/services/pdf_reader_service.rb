# app/services/pdf_reader_service.rb
require "pdf-reader"

class PdfReaderService
  def self.extract_text(file_path)
    reader = PDF::Reader.new(file_path)
    text = reader.pages.map(&:text).join("\n")
    text
  rescue => e
    Rails.logger.error("Erreur lecture PDF : #{e.message}")
    ""
  end

  # Détection automatique de la banque
  def self.detect_bank(text)
    return :credit_mutuel   if text =~ /Crédit\s+Mutuel/i
    return :credit_agricole if text =~ /Crédit\s+Agricole/i
    return :banque_postale  if text =~ /Banque\s+Postale/i

    :default
  end
end
