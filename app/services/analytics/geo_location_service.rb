require 'maxmind/db'

module Analytics
  class GeoLocationService
    attr_reader :ip_address

    def initialize(ip_address)
      @ip_address = ip_address
    end

    def call
      return default_location if ip_address.blank? || local_ip?
      
      begin
        geoip_result = geoip_client.get(ip_address)
        {
          country_code: geoip_result['country']['iso_code'],
          region: geoip_result['subdivisions']&.first&.fetch('name', 'Unknown'),
          city: geoip_result['city']&.fetch('name', 'Unknown')
        }
      rescue StandardError => e
        Rails.logger.error("GeoIP lookup failed: #{e.message}")
        default_location
      end
    end

    private

    def local_ip?
      ip_address == 'localhost' ||
        ip_address == '127.0.0.1' ||
        ip_address == '::1' ||
        ip_address.start_with?('192.168.', '10.', '172.')
    end

    def default_location
      {
        country_code: 'UN',
        region: 'Unknown',
        city: 'Unknown'
      }
    end

    def geoip_client
      @geoip_client ||= MaxMind::DB.new(
        Rails.root.join('db', 'GeoLite2-City.mmdb'),
        mode: MaxMind::DB::MODE_MEMORY
      )
    end
  end
end 