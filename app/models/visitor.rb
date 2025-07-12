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
    return if ip_address.blank?
    
    # IPv4 format validation with octet range check
    ipv4_regex = /\A(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\z/
    # IPv6 format validation (basic)
    ipv6_regex = /\A(?:[0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}\z/
    
    unless ip_address.match?(ipv4_regex) || ip_address.match?(ipv6_regex)
      errors.add(:ip_address, 'must be a valid IPv4 or IPv6 address')
    end
  end
end
