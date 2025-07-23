# frozen_string_literal: true

require_relative 'logger'

module PdfMaster
  class Modify
    class << self
      attr_accessor :pdf, :pdf_pages

      def load_pdf(input_pdf)
        @pdf = CombinePDF.load(input_pdf)
        @pdf_pages = @pdf.pages
      end

      def save_pdf(output_pdf)
        output_pdf = output_pdf.dup if output_pdf.frozen?
        begin
          @pdf.save(output_pdf)
        rescue RuntimeError => e
          Logger.log("Error saving PDF: #{e.message}")
          raise
        end
      end

      def add_page(input_pdf, *page_numbers)
        Logger.log("Adding blank pages to #{input_pdf} at positions #{page_numbers}")
        load_pdf(input_pdf)

        prawn_pdf = Prawn::Document.new { |pdf| pdf.start_new_page }
        blank_page = CombinePDF.parse(String.new(prawn_pdf.render).dup).pages[0]
        new_pdf = CombinePDF.new

        page_numbers = page_numbers.map(&:to_i).sort.uniq
        max_pages = @pdf_pages.count + 1
        valid_positions = page_numbers.select { |pos| pos.between?(1, max_pages) }
        
        insert_index = 0
        @pdf.pages.each_with_index do |page, index|
          while insert_index < valid_positions.size && valid_positions[insert_index] - 1 == index
            new_pdf << blank_page
            insert_index += 1
          end
          new_pdf << page
        end

        while insert_index < valid_positions.size && valid_positions[insert_index] == max_pages
          new_pdf << blank_page
          insert_index += 1
        end
        
        @pdf = new_pdf
        @pdf = @pdf.dup unless @pdf.nil? || !@pdf.frozen?

        save_pdf(input_pdf)
        Logger.log("Blank pages added successfully.")
      rescue => e
        Logger.log("Error adding pages: #{e.message}")
        raise
      end

      def remove_page(input_pdf, *page_numbers)
        Logger.log("Removing pages #{page_numbers} from #{input_pdf}")
        load_pdf(input_pdf)

        page_numbers = page_numbers.map(&:to_i).sort.uniq
        max_pages = @pdf.pages.count
        valid_positions = page_numbers.select { |pos| pos.between?(1, max_pages) }

        if valid_positions.empty?
          raise ArgumentError, "Invalid page numbers: #{page_numbers}"
        end

        new_pdf = CombinePDF.new
        @pdf.pages.each_with_index do |page, index|
          new_pdf << page unless valid_positions.include?(index + 1)
        end

        @pdf = new_pdf
        save_pdf(input_pdf)
        Logger.log("Pages #{valid_positions} removed successfully.")
      rescue => e
        Logger.log("Error removing pages: #{e.message}")
        raise
      end

      def rotate_page(input_pdf, degrees, *page_numbers)
        Logger.log("Rotating pages #{page_numbers} of #{input_pdf} by #{degrees} degrees")
        load_pdf(input_pdf)
      
        page_numbers = page_numbers.map(&:to_i).uniq
        max_pages = @pdf_pages.count
        valid_positions = page_numbers.select { |pos| pos.between?(1, max_pages) }
      
        valid_positions.each do |page_number|
          current_rotation = @pdf_pages[page_number - 1][:Rotate].to_i
          @pdf_pages[page_number - 1][:Rotate] = (current_rotation + degrees) % 360
        end
      
        save_pdf(input_pdf)
        Logger.log("Pages rotated successfully.")
      rescue => e
        Logger.log("Error rotating pages: #{e.message}")
        raise
      end

      def duplicate_pages(input_pdf, *page_numbers)
        Logger.log("Duplicating pages #{page_numbers} in #{input_pdf}")

        doc = HexaPDF::Document.open(input_pdf)
        max_pages = doc.pages.count
        valid_positions = page_numbers.map(&:to_i).uniq.select { |pos| pos.between?(1, max_pages) }

        return if valid_positions.empty?

        valid_positions.sort.reverse.each do |page_number|
          page_index = page_number - 1
          original_page = doc.pages[page_index]

          # Correctly duplicate using `doc.import`
          duplicated_page = doc.import(original_page)

          # Insert the duplicated page right after the original
          doc.pages.insert(page_index + 1, duplicated_page)
        end

        doc.write(input_pdf, optimize: true)
        Logger.log("Pages duplicated successfully.")
      rescue => e
        Logger.log("Error duplicating pages: #{e.message}")
        raise
      end

      def duplicate_and_place(input_pdf, page_number, target_position, count = 1, doc = nil)
        Logger.log("Duplicating page #{page_number} and placing #{count} copies at position #{target_position} in #{input_pdf}")

        doc_opened_here = doc.nil?
        doc ||= HexaPDF::Document.open(input_pdf)
        max_pages = doc.pages.count
        return unless page_number.between?(1, max_pages)

        page_index = page_number - 1
        target_index = [[target_position - 1, max_pages].min, 0].max

        original_page = doc.pages[page_index]

        count.times do
          duplicated_page = doc.import(original_page) # Import avoids extra blank pages
          doc.pages.insert(target_index, duplicated_page)
          target_index += 1 # Adjust index dynamically to maintain order
        end

        if doc_opened_here
          doc.write(input_pdf, optimize: true)
          Logger.log("Successfully duplicated page #{page_number} and inserted at position #{target_position} #{count} times.")
        end
      rescue => e
        Logger.log("Error in duplication: #{e.message}")
        raise
      end

      def merge_pdfs(output_pdf, *input_pdfs)
        raise ArgumentError, "No input PDFs provided." if input_pdfs.empty?
      
        Logger.log("Merging PDFs into #{output_pdf}: #{input_pdfs.join(', ')}")
      
        combined_pdf = CombinePDF.new
      
        input_pdfs.each do |file|
          unless File.exist?(file) && File.readable?(file)
            raise ArgumentError, "File does not exist or is not readable: #{file}"
          end
      
          begin
            combined_pdf << CombinePDF.load(file)
          rescue => e
            Logger.log("Error loading file #{file}: #{e.message}")
            raise "Failed to load PDF: #{file}"
          end
        end
      
        begin
          combined_pdf.save(output_pdf)
          Logger.log("PDFs merged successfully into #{output_pdf}.")
        rescue => e
          Logger.log("Error saving merged PDF: #{e.message}")
          raise "Failed to save merged PDF."
        end
      end

      def split_pdf(input_pdf, split_page)
        Logger.log("Splitting #{input_pdf} at page #{split_page}")
      
        doc = HexaPDF::Document.open(input_pdf)
        total_pages = doc.pages.count
      
        raise ArgumentError, "Split page #{split_page} is out of range. Total pages: #{total_pages}" if split_page <= 0 || split_page > total_pages
      
        timestamp = Time.now.to_i
        output_dir = defined?(Rails) ? Rails.root.join('public', 'uploads') : 'public/uploads'
        FileUtils.mkdir_p(output_dir) unless Dir.exist?(output_dir)

        output_pdf1 = File.join(output_dir, "#{File.basename(input_pdf, '.pdf')}_part1_#{timestamp}.pdf")
        output_pdf2 = File.join(output_dir, "#{File.basename(input_pdf, '.pdf')}_part2_#{timestamp}.pdf")
      
        # Create new PDF documents
        doc1 = HexaPDF::Document.new
        doc2 = HexaPDF::Document.new
      
        # Copy pages into the new documents while preserving contents
        (0...split_page).each do |i|
          new_page = doc1.import(doc.pages[i]) # Properly import page
          doc1.pages.add(new_page)
        end
      
        (split_page...total_pages).each do |i|
          new_page = doc2.import(doc.pages[i]) # Properly import page
          doc2.pages.add(new_page)
        end
      
        # Write output PDFs
        doc1.write(output_pdf1, optimize: true)
        doc2.write(output_pdf2, optimize: true)
      
        Logger.log("PDF split successfully into #{output_pdf1} and #{output_pdf2}")
      
        return output_pdf1, output_pdf2
      rescue => e
        Logger.log("Error splitting PDF: #{e.message}")
        raise
      end

      def extract_pages(input_pdf, page_numbers, output_pdf)
        Logger.log("Extracting pages #{page_numbers.join(', ')} from #{input_pdf}")
        
        doc = CombinePDF.load(input_pdf)
        extracted = CombinePDF.new
        
        page_numbers.each do |page_number|
          extracted << doc.pages[page_number - 1] if page_number.between?(1, doc.pages.count)
        end
        
        extracted.save(output_pdf)
        Logger.log("Pages extracted successfully into #{output_pdf}")
      rescue => e
        Logger.log("Error extracting pages: #{e.message}")
        raise
      end

      ACTIONS = {
        move_up: ->(pages, *indices) { move_pages(pages, indices, -1) },
        move_down: ->(pages, *indices) { move_pages(pages, indices, +1) },
        move_first: ->(pages, *indices) { move_pages(pages, indices, :first) },
        move_last: ->(pages, *indices) { move_pages(pages, indices, :last) },
        swap: ->(pages, index1, index2) { pages[index1 - 1], pages[index2 - 1] = pages[index2 - 1], pages[index1 - 1] },
        move_to: ->(pages, from, to) { pages.insert(to - 1, pages.delete_at(from - 1)) }
      }.freeze

      def rearrange_pages(input_pdf, action, *args)
        Logger.log("Rearranging pages in #{input_pdf} using action: #{action} with args: #{args}")

        raise ArgumentError, "Invalid action" unless ACTIONS.key?(action)

        load_pdf(input_pdf)

        begin
          ACTIONS[action].call(@pdf_pages, *args)

          @pdf = CombinePDF.new
          @pdf_pages.each { |page| @pdf << page }

          save_pdf(input_pdf)
          Logger.log("Successfully rearranged pages.")
        rescue => e
          Logger.log("Error rearranging pages: #{e.message}")
          raise
        end
      end

      def encrypt_pdf(input_pdf, output_pdf, password)
        Logger.log("Encrypting #{input_pdf} with a password")

        doc = HexaPDF::Document.open(input_pdf)
        doc.encrypt(:owner_password => password, :user_password => password)
        doc.write(output_pdf)

        Logger.log("PDF encrypted successfully: #{output_pdf}")
      rescue => e
        Logger.log("Error encrypting PDF: #{e.message}")
        raise
      end

      def compress_pdf(input_pdf, output_pdf = input_pdf)
        Logger.log("Compressing #{input_pdf}")

        doc = HexaPDF::Document.open(input_pdf)
        doc.write(output_pdf, optimize: true)

        Logger.log("PDF compressed successfully: #{output_pdf}")
      rescue => e
        Logger.log("Error compressing PDF: #{e.message}")
        raise
      end

      def crop_page(input_pdf, page_number, left, bottom, width, height)
        Logger.log("Cropping page #{page_number} of #{input_pdf}")

        doc = HexaPDF::Document.open(input_pdf)
        raise ArgumentError, "Invalid page number" unless page_number.between?(1, doc.pages.count)

        right  = left + width
        top    = bottom + height
        doc.pages[page_number - 1].box(:crop, [left, bottom, right, top])
        doc.write(input_pdf, optimize: true)

        Logger.log("Page cropped successfully.")
      rescue => e
        Logger.log("Error cropping page: #{e.message}")
        raise
      end

      private

      def self.move_pages(pages, indices, direction)
        indices = indices.map { |i| i - 1 }.sort
        indices.reverse! if direction == :last || direction == +1
  
        indices.each do |index|
          case direction
          when -1  then pages.insert([index - 1, 0].max, pages.delete_at(index))  # Move Up
          when +1  then pages.insert([index + 1, pages.size - 1].min, pages.delete_at(index))  # Move Down
          when :first then pages.unshift(pages.delete_at(index))  # Move First
          when :last  then pages.push(pages.delete_at(index))  # Move Last
          end
        end
      end
    end
  end
end
