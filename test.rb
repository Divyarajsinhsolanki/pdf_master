require_relative "lib/pdf_modifier"

pdf_path = "/home/divyarajs/Downloads/sample2.pdf"



# PdfModifier::Modifier.remove_page(pdf_path, pdf_path, 1)

# PdfModifier::Modifier.merge_pdfs(pdf_path,pdf_path,pdf_path)

# PdfModifier::Modifier.extract_pages(pdf_path , pdf_path, 1, 3, 5)

# PdfModifier::Modifier.rotate_page(pdf_path, pdf_path, 1, 0)

# PdfModifier::Modifier.add_watermark(pdf_path, pdf_path, "CONFIDENTIAL XYZ")



# PdfModifier::Modifier.add_blank_page(pdf_path, "pdf_path.pdf", :beginning) # Adds at the start
# PdfModifier::Modifier.add_blank_page(pdf_path, "pdf_path.pdf", :end) # Adds at the end
# PdfModifier::Modifier.add_blank_page(pdf_path, "pdf_path.pdf", 1) # Adds after page 2 (before page 3)





# PdfModifier::Modifier.add_text(pdf_path, pdf_path, "This text will be in top", 200, 900, 1)





# puts "Total pages: #{PdfModifier::Modifier.page_count(pdf_path)}"
# puts PdfModifier::Modifier.extract_text(pdf_path)
