module PdfModifier
  # ✅ page_count(input_pdf): Get the total number of pages.
  # ✅ extract_text(input_pdf): Extract text from all pages.
  # ✅ extract_metadata(input_pdf): Extract metadata (title, author, creation date, etc.).
  # ✅ get_dimensions(input_pdf): Get PDF page width & height.
  # ✅ list_fonts(input_pdf): Get a list of all fonts used in the PDF.
  # ✅ list_annotations(input_pdf): Extract annotations and comments from PDF pages.

  class Reader
    class << self
      attr_accessor :pdf, :pdf_pages

      def load_pdf(input_pdf)
        @pdf = CombinePDF.load(input_pdf)
        @pdf_pages = @pdf.pages
      end

      def page_count(input_pdf)
        load_pdf(input_pdf)
        @pdf_pages.count
      end

      def extract_text(input_pdf)
        reader = PDF::Reader.new(input_pdf)
        text = reader.pages.map(&:text).join("\n")
        text
      end

      def extract_metadata(input_pdf)
        reader = PDF::Reader.new(input_pdf)
        reader.metadata
      end

      def get_dimensions(input_pdf)
        load_pdf(input_pdf)
        page = @pdf_pages.first
        { width: page[:MediaBox][2], height: page[:MediaBox][3] }
      end

      def list_fonts(input_pdf)
        reader = PDF::Reader.new(input_pdf)
        fonts = reader.pages.map do |page|
          page.fonts.map { |_, font| font.basefont.to_s }
        end.flatten.uniq
        fonts
      end

      def list_annotations(input_pdf)
        reader = PDF::Reader.new(input_pdf)
        annotations = reader.pages.map do |page|
          page.attributes[:Annots]
        end.compact
        annotations
      end
    end
  end
end
  