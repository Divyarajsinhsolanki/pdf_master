module PdfModifier
  class Security

    # Encrypt a PDF with a password
    def self.secure_pdf(input_pdf, output_pdf, password)
      pdf = CombinePDF.load(input_pdf)
      pdf.encrypt(owner_password: password, user_password: password)
      pdf.save(output_pdf)
    end
  end
end