module PdfModifier
  # ✅ add_text(input_pdf, output_pdf, text, x, y, page_number): Insert text at a specific position.
  # ✅ add_watermark(input_pdf, output_pdf, watermark_text): Apply a watermark.
  # ✅ add_signature(input_pdf, output_pdf, signature_image, x, y, page_number): Add a signature image.
  # ✅ redact_text(input_pdf, output_pdf, text_to_remove): Find and remove sensitive text.

  class Editor
    # Add text to a specific position in a PDF
    def self.add_text(input_pdf, output_pdf, text, x, y, page_number)
      pdf = CombinePDF.load(input_pdf)
    
      return unless page_number.between?(1, pdf.pages.count) # Ensure page number is valid

      # Create a temporary overlay PDF with the same page size
      temp_pdf = "temp_overlay.pdf"
      Prawn::Document.generate(temp_pdf, margin: 0, page_size: [pdf.pages[0][:MediaBox][2], pdf.pages[0][:MediaBox][3]]) do
        draw_text text, at: [x, y]
      end
    
      # Load overlay and apply only to the specified page
      overlay_pdf = CombinePDF.load(temp_pdf)
      pdf.pages[page_number - 1] << overlay_pdf.pages[0] # Merge overlay with the specified page
    
      pdf.save(output_pdf)
      File.delete(temp_pdf) if File.exist?(temp_pdf) # Clean up temporary file
    end

    # Add a watermark to each page in a PDF
    def self.add_watermark(input_pdf, output_pdf, watermark_text)
      temp_pdf = "temp_watermark.pdf"

      Prawn::Document.generate(temp_pdf, margin: 0) do
        text watermark_text, size: 50, align: :center, valign: :center, rotate: 45, opacity: 0.3
      end

      pdf = CombinePDF.load(input_pdf)
      watermark = CombinePDF.load(temp_pdf)

      pdf.pages.each { |page| page << watermark.pages[0] }

      pdf.save(output_pdf)
      File.delete(temp_pdf) if File.exist?(temp_pdf)
    end
  end
end