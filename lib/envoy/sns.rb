module Envoy
  class Sns
    def self.client config
      attrs = {}
      attrs[:endpoint] = config.sns.endpoint unless config.sns.endpoint.blank?
      Aws::SNS::Client.new attrs
    end
  end
end
