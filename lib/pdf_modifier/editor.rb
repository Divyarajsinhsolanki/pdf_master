module PdfModifier
  require_relative 'logger'

  class Editor
    class << self

      # Unified method for cleanup
      def cleanup_temp_file(file)
        File.delete(file) if File.exist?(file)
      end

      # Add text to a specific position in a PDF
      def add_text(input_pdf, text, x, y, page_number)
        Logger.log("Adding text to page #{page_number} at position (#{x}, #{y})")
        
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

        Logger.log("Text added successfully to page #{page_number}.")
      rescue => e
        Logger.log("Error adding text: #{e.message}")
        raise
      end

      # Add a watermark to each page in a PDF
      def add_watermark(input_pdf, watermark_text, options = {})
        Logger.log("Adding watermark: '#{watermark_text}'")

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

        Logger.log("Watermark added successfully.")
      rescue => e
        Logger.log("Error adding watermark: #{e.message}")
        raise
      end

      # Add a signature image to a specific position in a PDF
      def add_signature(input_pdf, signature_image, x, y, page_number)
        Logger.log("Adding signature to page #{page_number} at position (#{x}, #{y})")

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

        Logger.log("Signature added successfully to page #{page_number}.")
      rescue => e
        Logger.log("Error adding signature: #{e.message}")
        raise
      end

      # Redact specified text from the PDF
      def replace_text(input_pdf, text_to_remove)
        Logger.log("Redacting text: '#{text_to_remove}' from #{input_pdf}")

        doc = HexaPDF::Document.open(input_pdf)

        doc.pages.each do |page|
          next unless page.contents
          content = page.contents
          content = content.gsub(text_to_remove, "Divyaraj") if content.is_a?(String)
          page[:Contents] = doc.add({Filter: :FlateDecode}, stream: content)
        end

        doc.write(input_pdf, optimize: true)
        
        Logger.log("Text redacted successfully.")
      rescue => e
        Logger.log("Error redacting text: #{e.message}")
        raise
      end
    end
  end
end
