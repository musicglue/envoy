module Envoy
  module Logging
    module_function

    def escape string
      string.gsub(/"/, '"')
    end

    def format_backtrace backtrace
      backtrace.map { |line| %("#{line}") }.join(', ')
    end

    def format_hash hash
      hash.map do |k, v|
        v = Envoy::Logging.escape v.to_s
        %(#{k}="#{v}")
      end.join ' '
    end

    def debug data, error = nil
      log_with_celluloid :debug, data, error
    end

    def info data, error = nil
      log_with_celluloid :info, data, error
    end

    def warn data, error = nil
      log_with_celluloid :warn, data, error
    end

    def error data, error = nil
      log_with_celluloid :error, data, error
    end

    def log_with_celluloid level, data, error = nil
      if data.is_a?(StandardError) && error.nil?
        data = nil
        error = data
      end

      data = format_hash(data) if data.is_a? Hash

      error = format_hash(
        error: error.to_s,
        backtrace: format_backtrace(error.backtrace)) if error

      string = "at=#{level} #{data} #{error}".strip

      Celluloid.logger.send(level, string) if Celluloid.logger
    end
  end
end
