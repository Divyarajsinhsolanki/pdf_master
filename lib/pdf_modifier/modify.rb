module PdfModifier
  # ✅ add_page(input_pdf, position = :end): Insert a blank page at a specific position.
  # ✅ remove_page(input_pdf, page_number): Remove a specific page.
  # ✅ rotate_page(input_pdf, page_number, degrees): Rotate a specific page.
  # ✅ split_pdf(input_pdf, output_folder): Split a PDF into individual pages.
  # ✅ merge_pdfs(*input_pdfs): Merge multiple PDFs into one.
  # ✅ reorder_pages(input_pdf, new_order): Reorder pages in a custom order.

  class Modify
    class << self
      attr_accessor :pdf, :pdf_pages

      # Load PDF and initialize instance variables
      def load_pdf(input_pdf)
        @pdf = CombinePDF.load(input_pdf)
        @pdf_pages = @pdf.pages
      end
      # ✅ Save PDF (overwrites input file)
      def save_pdf(output_pdf)
        @pdf.save(output_pdf)
      end

      # ✅ Add a blank page at a specific page_number
      def add_page(input_pdf, page_number)
        load_pdf(input_pdf)

        blank_page = CombinePDF.parse(Prawn::Document.new { |pdf| pdf.start_new_page }.render).pages[0]
        new_pdf = CombinePDF.new

        if !(page_number.to_i.between?(1, @pdf_pages.count + 1))
          @pdf.pages.each { |page| new_pdf << page }
          new_pdf << blank_page
        else
          page_number = page_number.to_i
          @pdf.pages.each_with_index do |page, index|
            new_pdf << blank_page if index == page_number - 1
            new_pdf << page
          end
          # If adding at the last position, ensure the blank page is added
          new_pdf << blank_page if page_number == @pdf_pages.count + 1
        end
      
        @pdf = new_pdf
        save_pdf(input_pdf)
      end

      # ✅ Remove a specific page
      def remove_page(input_pdf, page_number)
        load_pdf(input_pdf)
      
        if (page_number = page_number&.to_i) && page_number.between?(1, @pdf.pages.count)
          new_pdf = CombinePDF.new
          @pdf.pages.each_with_index do |page, index|
            new_pdf << page unless index == (page_number - 1)
          end
      
          @pdf = new_pdf # ✅ Reassign to the modified PDF
          save_pdf(input_pdf)
        else
          raise ArgumentError, "Invalid page number: #{page_number}"
        end
      end

      # ✅ Merge multiple PDFs into one
      def merge_pdfs(output_pdf, *input_pdfs)
        raise ArgumentError, "No PDFs provided for merging" if input_pdfs.empty?

        combined_pdf = CombinePDF.new
        input_pdfs.each do |file|
          raise ArgumentError, "File does not exist: #{file}" unless File.exist?(file)
          combined_pdf << CombinePDF.load(file)
        end

        combined_pdf.save(output_pdf)
      end

      # ✅ Extract specific pages into a new PDF
      def extract_pages(input_pdf, output_pdf, *page_numbers)
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
      end

      # ✅ Rotate a specific page
      def rotate_page(input_pdf, page_number, degrees)
        load_pdf(input_pdf)
      
        if page_number.between?(1, @pdf_pages.count)
          @pdf_pages[page_number - 1][:Rotate] = degrees
          save_pdf(input_pdf)
        else
          raise ArgumentError, "Invalid page number: #{page_number}"
        end
      end

      # ✅ Split a PDF into separate pages
      def split_pdf(input_pdf, output_folder)
        load_pdf(input_pdf)
        raise ArgumentError, "Output folder does not exist: #{output_folder}" unless Dir.exist?(output_folder)

        @pdf_pages.each_with_index do |page, index|
          new_pdf = CombinePDF.new << page
          new_pdf.save(File.join(output_folder, "page_#{index + 1}.pdf"))
        end
      end

      # ✅ Reorder pages in a custom order
      def reorder_pages(input_pdf, output_pdf, new_order)
        load_pdf(input_pdf)

        if new_order.sort != (1..@pdf_pages.count).to_a
          raise ArgumentError, "Invalid page order. Must include all pages exactly once."
        end

        reordered_pdf = CombinePDF.new
        new_order.each { |i| reordered_pdf << @pdf_pages[i - 1] }

        reordered_pdf.save(output_pdf)
      end
    end
  end
end
