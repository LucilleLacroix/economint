class BanquePostaleParser
  def self.parse(text)
    PdfTransactionParser.parse(text)
  end
end
