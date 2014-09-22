module Envoy
  class MessageSanitizer
    def sanitize hash
      {
        header: (hash['headers'] || hash['header']),
        body: hash['body']
      }.with_indifferent_access
    end
  end
end
