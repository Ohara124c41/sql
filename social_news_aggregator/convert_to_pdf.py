from weasyprint import HTML

# Convert HTML to PDF
html_file = r'c:\Users\Ohara\Desktop\__Udacity\sql\social_news_aggregator\udiddit_report.html'
pdf_file = r'c:\Users\Ohara\Desktop\__Udacity\sql\social_news_aggregator\udiddit_report.pdf'

HTML(filename=html_file).write_pdf(pdf_file)
print(f"PDF created successfully: {pdf_file}")
