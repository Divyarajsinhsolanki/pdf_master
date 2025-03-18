module PdfModifier
  class Validator
    def self.validate_pdf(pdf_path)
      raise ArgumentError, "File does not exist: #{pdf_path}" unless File.exist?(pdf_path)
      raise ArgumentError, "File is not a PDF: #{pdf_path}" unless File.extname(pdf_path).downcase == ".pdf"
      raise ArgumentError, "File is not accessible." unless File.readable?(pdf_path)

      begin
        CombinePDF.load(pdf_path)
      rescue StandardError
        raise ArgumentError, "PDF is corrupted or inaccessible: #{pdf_path}"
      end
    end
  end
end