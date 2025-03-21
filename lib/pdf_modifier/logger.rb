require 'logger'

module PdfModifier
  class Logger
    def self.instance
      @logger ||= begin
        file_logger = ::Logger.new(File.join(Dir.pwd, 'pdf_modifier.log'), 'daily')
        file_logger.level = ::Logger::INFO
        
        console_logger = ::Logger.new(STDOUT)
        console_logger.level = ::Logger::INFO

        [file_logger, console_logger]
      end
    end

    def self.log(message, level = :info)
      file_logger, console_logger = instance
      file_logger.send(level, message)
      console_logger.send(level, message)
    end

    def self.log_and_raise(error_class, message)
      log(message, :error)
      raise error_class, message
    end
  end
end
