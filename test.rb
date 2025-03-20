require_relative "lib/pdf_modifier"

pdf_path = "/home/divyarajs/Downloads/sample.pdf"
# pdf_path = "/home/divyarajs/react_projects/rails_vite/public/uploads/45297724-e8ed-4a28-836c-c7982271e625_working.pdf"



# PdfModifier.add_page(pdf_path, 1)
PdfModifier.remove_page(pdf_path, 1)
# PdfModifier.add_text(pdf_path, "WWWWWWWWWW" , 200, 100, 1)


# PdfModifier.merge_pdfs(pdf_path,pdf_path,pdf_path)

# PdfModifier.extract_pages(pdf_path , 1, 3, 5)

# PdfModifier.rotate_page(pdf_path, 1, 0)

# PdfModifier.add_watermark(pdf_path, "CONFIDENTIAL XYZ")



# PdfModifier.add_page(pdf_path, "pdf_path.pdf", :beginning) # Adds at the start
# PdfModifier.add_page(pdf_path, "pdf_path.pdf", :end) # Adds at the end
# PdfModifier.add_page(pdf_path, "pdf_path.pdf", 1) # Adds after page 2 (before page 3)





# PdfModifier.add_text(pdf_path, "qqqqqq", 300, 300, 1)





# puts "Total pages: #{PdfModifier.page_count(pdf_path)}"
# puts PdfModifier.extract_text(pdf_path)
