module Analytics
  class SourceDetectorService
    SEARCH_ENGINES = [
      'google', 'bing', 'yahoo', 'duckduckgo', 'baidu', 'yandex'
    ].freeze

    SOCIAL_NETWORKS = [
      'facebook', 'twitter', 'linkedin', 'instagram', 'pinterest',
      'reddit', 'youtube', 'tiktok'
    ].freeze

    attr_reader :referrer

    def initialize(referrer)
      @referrer = referrer.to_s.downcase
    end

    def source_type
      return 'direct' if referrer.blank?
      return 'search' if from_search_engine?
      return 'social' if from_social_network?
      'referral'
    end

    private

    def from_search_engine?
      SEARCH_ENGINES.any? { |engine| referrer.include?(engine) }
    end

    def from_social_network?
      SOCIAL_NETWORKS.any? { |network| referrer.include?(network) }
    end
  end
end 