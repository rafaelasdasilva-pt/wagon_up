require 'pdf-reader'
require 'docx'

class PdfParser
  MAX_CHARS = 12_000
  SUPPORTED_TYPES = %w[application/pdf application/vnd.openxmlformats-officedocument.wordprocessingml.document].freeze

  def self.extract(file)
    new(file).extract
  end

  def initialize(file)
    @file = file
  end

  def extract
    content_type = @file.blob.content_type
    filename = @file.blob.filename.to_s
    path = active_storage_path(@file)

    text = if content_type == "application/pdf" || filename.end_with?(".pdf")
      read_pdf(path)
    elsif content_type == "application/vnd.openxmlformats-officedocument.wordprocessingml.document" || filename.end_with?(".docx")
      read_docx(path)
    else
      raise PdfParserError, "Formato não suportado. Usa PDF ou Word (.docx)."
    end

    raise PdfParserError, "Ficheiro vazio ou ilegível" if text.blank?
    text.strip.truncate(MAX_CHARS, omission: "... [truncado]")
  rescue PDF::Reader::MalformedPDFError
    raise PdfParserError, "PDF corrompido ou inválido"
  end

  private

  def active_storage_path(file)
    ActiveStorage::Blob.service.path_for(file.blob.key).to_s
  end

  def read_pdf(path)
    reader = PDF::Reader.new(path)
    reader.pages.map(&:text).join("\n")
  end

  def read_docx(path)
    doc = Docx::Document.open(path)
    doc.paragraphs.map(&:to_s).join("\n")
  end
end

class PdfParserError < StandardError; end
