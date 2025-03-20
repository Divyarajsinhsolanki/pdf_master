require "hexapdf"
require "combine_pdf"
require "prawn"
require "pdf-reader"

module PdfModifier
  require_relative "pdf_modifier/validator"
  require_relative "pdf_modifier/editor"
  require_relative "pdf_modifier/modify"
  require_relative "pdf_modifier/reader"
  require_relative "pdf_modifier/security"

  require_relative 'pdf_modifier/logger'
  require_relative 'pdf_modifier/errors'

  include PdfModifier::Errors

def self.method_missing(method_name, *args, **kwargs, &block)
    Validator.validate_pdf(args.first) if args.any?

    # Delegate the call to appropriate class
    [Modify, Editor, Reader, Security].each do |klass|
      if klass.respond_to?(method_name)
        return klass.public_send(method_name, *args, **kwargs, &block)
      end
    end

    super
  end

  def self.respond_to_missing?(method_name, include_private = false)
    [Modify, Editor, Reader, Security].any? { |klass| klass.respond_to?(method_name) } || super
  end
end
