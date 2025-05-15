class Visitor < ApplicationRecord
  has_many :visits
  
  validates :uuid, presence: true, uniqueness: true
  validates :ip_address, presence: true
  validates :user_agent, presence: true, length: { maximum: 500 }
  
  # Validate IP address format
  validate :validate_ip_address
  
  # Sanitize inputs
  before_validation :sanitize_inputs
  
  def self.find_or_create_from_request(request, current_uuid = nil)
    visitor = if current_uuid.present?
                find_by(uuid: current_uuid)
              else
                # Create a new visitor
                nil
              end
    
    unless visitor
      visitor = create!(
        uuid: current_uuid || SecureRandom.uuid,
        ip_address: request.remote_ip || request.ip,
        user_agent: request.user_agent,
        first_visit_at: Time.current
      )
    end
    
    visitor
  end
  
  private
  
  def sanitize_inputs
    self.user_agent = user_agent.to_s.strip
    self.ip_address = ip_address.to_s.strip
  end

  def validate_ip_address
    # Allow empty IP for validation chain
    return if ip_address.blank?
    
    # Try to parse the IP address
    begin
      # Handle special cases
      return if ip_address == 'localhost' ||
                ip_address == '127.0.0.1' ||
                ip_address == '::1' ||
                ip_address.start_with?('192.168.') ||
                ip_address.start_with?('10.') ||
                ip_address.start_with?('172.')
      
      # Try to parse as IPv4
      if ip_address.include?('.')
        parts = ip_address.split('.')
        if parts.length == 4 && parts.all? { |part| part.to_i.between?(0, 255) }
          return
        end
      end
      
      # Try to parse as IPv6
      if ip_address.include?(':')
        require 'ipaddr'
        IPAddr.new(ip_address)
        return
      end
      
      errors.add(:ip_address, 'is not a valid IP address')
    rescue IPAddr::InvalidAddressError
      errors.add(:ip_address, 'is not a valid IP address')
    end
  end
end
