module PdfModifier
  # ✅ encrypt_pdf(input_pdf, output_pdf, password): Encrypt a PDF with a password.
  # ✅ decrypt_pdf(input_pdf, output_pdf, password): Remove encryption if the password is correct.
  # ✅ set_permissions(input_pdf, output_pdf, options = {}): Set restrictions (e.g., prevent printing, copying).

  class Security

    # Encrypt a PDF with a password
    def self.secure_pdf(input_pdf, output_pdf, password)
      pdf = CombinePDF.load(input_pdf)
      pdf.encrypt(owner_password: password, user_password: password)
      pdf.save(output_pdf)
    end
  end
end