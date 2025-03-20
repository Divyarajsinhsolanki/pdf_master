module PdfModifier
  # ✅ add_text(input_pdf, text, x, y, page_number): Insert text at a specific position.
  # ✅ add_watermark(input_pdf, watermark_text): Apply a watermark.
  # ✅ add_signature(input_pdf, signature_image, x, y, page_number): Add a signature image.
  # ✅ redact_text(input_pdf, text_to_remove): Find and remove sensitive text.

  class Editor
    class << self

      # Unified method for cleanup
      def cleanup_temp_file(file)
        File.delete(file) if File.exist?(file)
      end

      # Add text to a specific position in a PDF
      def add_text(input_pdf, text, x, y, page_number)
        pdf = CombinePDF.load(input_pdf)

        return unless page_number.between?(1, pdf.pages.count)

        temp_pdf = "temp_overlay.pdf"
        Prawn::Document.generate(temp_pdf, margin: 0, page_size: [pdf.pages[0][:MediaBox][2], pdf.pages[0][:MediaBox][3]]) do
          draw_text text, at: [x, y]
        end
        overlay_pdf = CombinePDF.load(temp_pdf)
        pdf.pages[page_number - 1] << overlay_pdf.pages[0]

        pdf.save(input_pdf)
        cleanup_temp_file(temp_pdf)
      end

      # Add a watermark to each page in a PDF
      def add_watermark(input_pdf, watermark_text, options = {})
        options = { size: 50, rotate: 45, opacity: 0.3 }.merge(options)
        temp_pdf = "temp_watermark.pdf"

        Prawn::Document.generate(temp_pdf, margin: 0) do
          fill_color "000000"
          transparent(options[:opacity]) do
            text watermark_text, size: options[:size], align: :center, rotate: options[:rotate]
          end
        end

        pdf = CombinePDF.load(input_pdf)
        watermark = CombinePDF.load(temp_pdf)
        pdf.pages.each { |page| page << watermark.pages[0] }

        pdf.save(input_pdf)
        cleanup_temp_file(temp_pdf)
      end

      # Add a signature image to a specific position in a PDF
      def add_signature(input_pdf, signature_image, x, y, page_number)
        raise ArgumentError, "Signature image file not found." unless File.exist?(signature_image)

        pdf = CombinePDF.load(input_pdf)
        return unless page_number.between?(1, pdf.pages.count)

        temp_pdf = "temp_signature.pdf"
        Prawn::Document.generate(temp_pdf, margin: 0, page_size: [pdf.pages[0][:MediaBox][2], pdf.pages[0][:MediaBox][3]]) do
          image signature_image, at: [x, y], width: 100
        end

        signature_pdf = CombinePDF.load(temp_pdf)
        pdf.pages[page_number - 1] << signature_pdf.pages[0]

        pdf.save(input_pdf)
        cleanup_temp_file(temp_pdf)
      end

      # Redact specified text from the PDF
      def redact_text(input_pdf, text_to_remove)
        reader = PDF::Reader.new(input_pdf)

        content = reader.pages.map(&:text).join("\n")
        updated_content = content.gsub(text_to_remove, "[REDACTED]")

        File.open(input_pdf, "w") { |f| f.write(updated_content) }
      end
    end
  end
end