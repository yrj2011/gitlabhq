# Class to parse and transform the info provided by omniauth
#
module Gitlab
  module LDAP
    class AuthHash < Gitlab::OAuth::AuthHash
      def uid
        Gitlab::LDAP::Person.normalize_dn(super)
      end

      private

      def get_info(key)
        attributes = ldap_config.attributes[key.to_s]
        return super unless attributes

        attributes = Array(attributes)

        value = nil
        attributes.each do |attribute|
          value = get_raw(attribute)
          value = value.first if value
          break if value.present?
        end

        return super unless value

        Gitlab::Utils.force_utf8(value)
        value
      end

      def get_raw(key)
        auth_hash.extra[:raw_info][key] if auth_hash.extra
      end

      def ldap_config
        @ldap_config ||= Gitlab::LDAP::Config.new(self.provider)
      end
    end
  end
end
