require "combine_pdf"
require "prawn"
require "pdf-reader"

module PdfModifier
  require_relative "pdf_modifier/reader"
  require_relative "pdf_modifier/modify"
  require_relative "pdf_modifier/editor"
  require_relative "pdf_modifier/security"

  class Modifier

    def initialize(pdf_path)
      @pdf = CombinePDF.load(pdf_path)
    end
  
    def page_count
      @pdf.pages.count
    end
  
    def save(output_pdf)
      @pdf.save(output_pdf)
    end
  end
end
