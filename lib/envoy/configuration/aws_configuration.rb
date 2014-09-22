module Envoy
  class Configuration
    class AwsConfiguration
      include Validatable

      attr_accessor :access_key,
                    :secret_key,
                    :region,
                    :account_id

      def validate
        errors << 'aws.access_key is required' if access_key.blank?
        errors << 'aws.secret_key is required' if secret_key.blank?
        errors << 'aws.region is required' if region.blank?
        errors << 'aws.account_id is required' if account_id.blank?
      end
    end
  end
end
