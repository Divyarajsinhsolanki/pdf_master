module PdfModifier
  # ✅ add_page(input_pdf, output_pdf, position = :end): Insert a blank page at a specific position.
  # ✅ remove_page(input_pdf, output_pdf, page_number): Remove a specific page.
  # ✅ rotate_page(input_pdf, output_pdf, page_number, degrees): Rotate a specific page.
  # ✅ split_pdf(input_pdf, output_folder): Split a PDF into individual pages.
  # ✅ merge_pdfs(output_pdf, *input_pdfs): Merge multiple PDFs into one.
  # ✅ reorder_pages(input_pdf, output_pdf, new_order): Reorder pages in a custom order.

  class Modifier

    def self.add_blank_page(input_pdf, output_pdf, position = :end)
      pdf = CombinePDF.load(input_pdf)

      blank_pdf_path = "blank_page.pdf"
      Prawn::Document.generate(blank_pdf_path, page_size: "A4") {}

      blank_page = CombinePDF.load(blank_pdf_path).pages[0]

      case position
      when :beginning
        pdf.pages.unshift(blank_page)
      when :end
        pdf.pages << blank_page
      when Integer
        if position.between?(1, pdf.pages.count + 1)
          pdf.pages.insert(position - 1, blank_page)
        else
          raise ArgumentError, "Invalid position: #{position}"
        end
      else
        raise ArgumentError, "Invalid position: Use :beginning, :end, or a page number."
      end

      pdf.save(output_pdf)
      File.delete(blank_pdf_path) if File.exist?(blank_pdf_path)
    end

    # Remove a specific page from a PDF
    def self.remove_page(input_pdf, output_pdf, page_number)
      pdf = CombinePDF.load(input_pdf)
      
      return unless page_number.between?(1, pdf.pages.count) # Ensure valid page
    
      pdf.pages.delete_at(page_number - 1) # Remove the page (0-based index)
      
      pdf.save(output_pdf)
      puts "Page #{page_number} removed successfully."
    end
    

    # Merge multiple PDFs into one
    def self.merge_pdfs(output_pdf, *input_pdfs)
      pdf = CombinePDF.new
      input_pdfs.each { |file| pdf << CombinePDF.load(file) }
      pdf.save(output_pdf)
    end

    # Extract specific pages into a new PDF
    def self.extract_pages(input_pdf, output_pdf, *page_numbers)
      pdf = CombinePDF.load(input_pdf)
      new_pdf = CombinePDF.new
      page_numbers.each { |page| new_pdf << pdf.pages[page - 1] if page.between?(1, pdf.pages.count) }
      new_pdf.save(output_pdf)
    end

    # Rotate a specific page by a given degree
    def self.rotate_page(input_pdf, output_pdf, page_number, degrees)
      pdf = CombinePDF.load(input_pdf)
      return unless page_number.between?(1, pdf.pages.count)
    
      page = pdf.pages[page_number - 1]
      page[:Rotate] = degrees  # Set the rotation attribute for the page
      
      pdf.save(output_pdf)
    end

    # Split a PDF into separate pages, each saved as an individual file
    def self.split_pdf(input_pdf, output_folder)
      pdf = CombinePDF.load(input_pdf)
      pdf.pages.each_with_index do |page, index|
        new_pdf = CombinePDF.new
        new_pdf << page
        new_pdf.save("#{output_folder}/page_#{index + 1}.pdf")
      end
    end
  end
end