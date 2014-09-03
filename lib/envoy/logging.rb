module Envoy
  module Logging
    module_function

    def escape string
      string.gsub(/"/, '"')
    end
  end
end
