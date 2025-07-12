# == Schema Information
#
# Table name: visits
#
#  id           :bigint           not null, primary key
#  visitor_id   :bigint           not null
#  page_path    :string
#  referrer     :string
#  device_type  :string
#  source_type  :string
#  country_code :string
#  region       :string
#  city         :string
#  duration     :integer
#  bounced      :boolean
#  entered_at   :datetime
#  exited_at    :datetime
#  site_url     :string
#  app_name     :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

class Visit < ApplicationRecord
  belongs_to :visitor
  has_many :page_views, dependent: :destroy
  
  validates :page_path, presence: true
  validates :entered_at, presence: true
  validates :page_views_count, numericality: { greater_than_or_equal_to: 0 }

  # Optionally, you can add validations for site_url and app_name if needed
  # validates :site_url, presence: true
  # validates :app_name, presence: true

  before_save :set_duration, if: :exited_at_changed?
  before_save :update_bounce_status, if: :page_views_count_changed?
  
  scope :bounced, -> { where(bounced: true) }
  scope :engaged, -> { where(bounced: false) }
  scope :in_progress, -> { where(exited_at: nil) }
  scope :completed, -> { where.not(exited_at: nil) }
  scope :from_desktop, -> { where(device_type: 'desktop') }
  scope :from_mobile, -> { where(device_type: 'mobile') }
  scope :from_tablet, -> { where(device_type: 'tablet') }
  scope :from_direct, -> { where(source_type: 'direct') }
  scope :from_search, -> { where(source_type: 'search') }
  scope :from_referral, -> { where(source_type: 'referral') }
  scope :from_social, -> { where(source_type: 'social') }
  scope :from_country, ->(country) { where(country_code: country) }
  
  def duration_in_seconds
    return 0 unless exited_at && entered_at
    (exited_at - entered_at).to_i
  end
  
  def mark_as_exited
    update(exited_at: Time.current)
    update_duration
  end
  
  def update_duration
    update(duration: duration_in_seconds)
  end
  
  def self.determine_device_type(user_agent)
    user_agent = user_agent.to_s.downcase
    
    if user_agent.match?(/ipad|tablet/)
      'tablet'
    elsif user_agent.match?(/mobile|iphone|android|blackberry/)
      'mobile'
    else
      'desktop'
    end
  end
  
  def self.determine_source_type(referrer)
    return 'direct' if referrer.blank?
    
    referrer = referrer.to_s.downcase
    
    if referrer.match?(/google|bing|yahoo|baidu|duckduckgo|yandex/)
      'search'
    elsif referrer.match?(/facebook|twitter|instagram|linkedin|tiktok|pinterest/)
      'social'
    else
      'referral'
    end
  end

  def bounce?
    page_views_count == 1
  end

  def end_visit
    return if exited_at.present?
    
    update(
      exited_at: Time.current,
      duration: calculate_duration
    )
  end

  private

  def set_duration
    self.duration = calculate_duration if exited_at.present?
  end

  def calculate_duration
    return 0 unless exited_at.present? && entered_at.present?
    (exited_at - entered_at).to_i
  end

  def update_bounce_status
    self.bounced = (page_views_count == 1)
  end
end