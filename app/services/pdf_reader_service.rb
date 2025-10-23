class PdfReaderService
  require "pdf-reader"

  def self.extract(file_path)
    reader = PDF::Reader.new(file_path)
    reader.pages.map(&:text).join("\n")
  rescue => e
    Rails.logger.error("Erreur lecture PDF : #{e.message}")
    ""
  end
end
