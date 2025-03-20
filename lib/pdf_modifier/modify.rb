module PdfModifier
  require_relative 'logger'

  class Modify
    class << self
      attr_accessor :pdf, :pdf_pages

      def load_pdf(input_pdf)
        @pdf = CombinePDF.load(input_pdf)
        @pdf_pages = @pdf.pages
      end

      def save_pdf(output_pdf)
        @pdf.save(output_pdf)
      end

      def add_page(input_pdf, page_number)
        Logger.log("Adding blank page to #{input_pdf} at position #{page_number}")
        load_pdf(input_pdf)

        blank_page = CombinePDF.parse(Prawn::Document.new { |pdf| pdf.start_new_page }.render).pages[0]
        new_pdf = CombinePDF.new
        page_number = page_number&.to_i
        if !(page_number.to_i.between?(1, @pdf_pages.count + 1))
          @pdf.pages.each { |page| new_pdf << page }
          new_pdf << blank_page
        else
          page_number = page_number.to_i
          @pdf.pages.each_with_index do |page, index|
            new_pdf << blank_page if index == page_number - 1
            new_pdf << page
          end
          new_pdf << blank_page if page_number == @pdf_pages.count + 1
        end

        @pdf = new_pdf
        save_pdf(input_pdf)

        Logger.log("Blank page added successfully.")
      rescue => e
        Logger.log("Error adding page: #{e.message}")
        raise
      end

      def remove_page(input_pdf, page_number)
        Logger.log("Removing page #{page_number} from #{input_pdf}")
        load_pdf(input_pdf)

        if (page_number = page_number&.to_i) && page_number.between?(1, @pdf.pages.count)
          new_pdf = CombinePDF.new
          @pdf.pages.each_with_index do |page, index|
            new_pdf << page unless index == (page_number - 1)
          end

          @pdf = new_pdf
          save_pdf(input_pdf)

          Logger.log("Page #{page_number} removed successfully.")
        else
          raise ArgumentError, "Invalid page number: #{page_number}"
        end
      rescue => e
        Logger.log("Error removing page: #{e.message}")
        raise
      end

      def merge_pdfs(output_pdf, *input_pdfs)
        Logger.log("Merging PDFs into #{output_pdf}: #{input_pdfs.join(', ')}")

        combined_pdf = CombinePDF.new
        input_pdfs.each do |file|
          raise ArgumentError, "File does not exist: #{file}" unless File.exist?(file)
          combined_pdf << CombinePDF.load(file)
        end

        combined_pdf.save(output_pdf)
        Logger.log("PDFs merged successfully.")
      rescue => e
        Logger.log("Error merging PDFs: #{e.message}")
        raise
      end

      def extract_pages(input_pdf, output_pdf, *page_numbers)
        Logger.log("Extracting pages #{page_numbers} from #{input_pdf} to #{output_pdf}")
        load_pdf(input_pdf)

        new_pdf = CombinePDF.new
        page_numbers.each do |page|
          if page.between?(1, @pdf_pages.count)
            new_pdf << @pdf_pages[page - 1]
          else
            raise ArgumentError, "Invalid page number: #{page}"
          end
        end

        new_pdf.save(output_pdf)
        Logger.log("Pages extracted successfully.")
      rescue => e
        Logger.log("Error extracting pages: #{e.message}")
        raise
      end

      def rotate_page(input_pdf, page_number, degrees)
        Logger.log("Rotating page #{page_number} of #{input_pdf} by #{degrees} degrees")
        load_pdf(input_pdf)

        if page_number.between?(1, @pdf_pages.count)
          current_rotation = @pdf_pages[page_number - 1][:Rotate].to_i
          @pdf_pages[page_number - 1][:Rotate] = (current_rotation + degrees) % 360
          save_pdf(input_pdf)

          Logger.log("Page rotated successfully.")
        else
          raise ArgumentError, "Invalid page number: #{page_number}"
        end
      rescue => e
        Logger.log("Error rotating page: #{e.message}")
        raise
      end

      def split_pdf(input_pdf, output_folder)
        Logger.log("Splitting #{input_pdf} into separate pages at #{output_folder}")
        load_pdf(input_pdf)

        raise ArgumentError, "Output folder does not exist: #{output_folder}" unless Dir.exist?(output_folder)

        @pdf_pages.each_with_index do |page, index|
          new_pdf = CombinePDF.new << page
          output_path = File.join(output_folder, "page_#{index + 1}.pdf")
          new_pdf.save(output_path)
        end

        Logger.log("PDF split successfully.")
      rescue => e
        Logger.log("Error splitting PDF: #{e.message}")
        raise
      end

      def reorder_pages(input_pdf, output_pdf, new_order)
        Logger.log("Reordering pages in #{input_pdf} with new order: #{new_order}")
        load_pdf(input_pdf)

        if new_order.sort != (1..@pdf_pages.count).to_a
          raise ArgumentError, "Invalid page order. Must include all pages exactly once."
        end

        reordered_pdf = CombinePDF.new
        new_order.each { |i| reordered_pdf << @pdf_pages[i - 1] }

        reordered_pdf.save(output_pdf)
        Logger.log("Pages reordered successfully.")
      rescue => e
        Logger.log("Error reordering pages: #{e.message}")
        raise
      end

      def duplicate_page(input_pdf, page_number)
        Logger.log("Duplicating page #{page_number} of #{input_pdf}")
        
        doc = HexaPDF::Document.open(input_pdf)
        page_index = page_number - 1
        original_page = doc.pages[page_index]

        raise ArgumentError, "Page number #{page_number} does not exist." if original_page.nil?

        new_page = doc.pages.add
        new_page[:Contents] = original_page[:Contents].dup
        new_page[:Resources] = original_page[:Resources].dup
        new_page.box(:media)

        doc.write(input_pdf, optimize: true)
        
        Logger.log("Page duplicated successfully.")
      rescue => e
        Logger.log("Error duplicating page: #{e.message}")
        raise
      end
    end
  end
end
