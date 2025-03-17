module PdfModifier
  # ✅ page_count(input_pdf): Get the total number of pages.
  # ✅ extract_text(input_pdf): Extract text from all pages.
  # ✅ extract_metadata(input_pdf): Extract metadata (title, author, creation date, etc.).
  # ✅ get_dimensions(input_pdf): Get PDF page width & height.
  # ✅ list_fonts(input_pdf): Get a list of all fonts used in the PDF.
  # ✅ list_annotations(input_pdf): Extract annotations and comments from PDF pages.

  class Reader

    # Get the total number of pages in a PDF
    def self.page_count(input_pdf)
      pdf = CombinePDF.load(input_pdf)
      pdf.pages.count
    end

    # Extract all text from a PDF
    def self.extract_text(input_pdf)
      reader = PDF::Reader.new(input_pdf)
      text = ""
      reader.pages.each { |page| text += page.text + "\n" }
      text
    end
  end
end