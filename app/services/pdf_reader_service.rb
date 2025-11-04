# app/services/pdf_reader_service.rb
require "pdf-reader"
require_relative "pdf_transaction_parser"

class PdfReaderService
  def self.extract_transactions(file_path)
    reader = PDF::Reader.new(file_path)
    text = reader.pages.map(&:text).join("\n")

    PdfTransactionParser.parse(text)
  rescue => e
    Rails.logger.error("Erreur lecture PDF : #{e.message}")
    []
  end
end
