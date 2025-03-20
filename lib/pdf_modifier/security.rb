module PdfModifier
  class Security
    class << self

      attr_accessor :pdf, :pdf_pages

      def load_pdf(input_pdf)
        @pdf = CombinePDF.load(input_pdf)
        @pdf_pages = @pdf.pages
      end

      # Encrypt a PDF with owner and user passwords
      def secure_pdf(input_pdf, owner_password, user_password)
        load_pdf(input_pdf)
        @pdf.encrypt(owner_password: owner_password, user_password: user_password)
        @pdf.save(input_pdf)
      end

      # Decrypt a secured PDF
      def decrypt_pdf(input_pdf, password)
        load_pdf(input_pdf)
        @pdf.decrypt(password)
        @pdf.save(input_pdf)
      end

      # Check if a PDF is encrypted
      def encrypted?(input_pdf)
        load_pdf(input_pdf)
        @pdf.encrypted?
      end

      # Add digital signature (Placeholder - Requires external library integration)
      def add_digital_signature(input_pdf, signature_file)
        load_pdf(input_pdf)
        # Placeholder: Implement digital signature integration
        @pdf.save(input_pdf)
      end
    end
  end
end
