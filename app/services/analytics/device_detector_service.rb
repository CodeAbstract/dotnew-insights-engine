module Analytics
  class DeviceDetectorService
    MOBILE_REGEX = /Mobile|iP(hone|od|ad)|Android|BlackBerry|IEMobile|Kindle|NetFront|Silk-Accelerated|(hpw|web)OS|Fennec|Minimo|Opera M(obi|ini)|Blazer|Dolfin|Dolphin|Skyfire|Zune/i
    TABLET_REGEX = /(ipad|tablet|(android(?!.*mobile))|(windows(?!.*phone)(.*touch))|kindle|playbook|silk|(puffin(?!.*(IP|AP|WP))))/i

    attr_reader :user_agent

    def initialize(user_agent)
      @user_agent = user_agent.to_s
    end

    def device_type
      return 'unknown' if user_agent.blank?
      return 'tablet' if tablet?
      return 'mobile' if mobile?
      'desktop'
    end

    private

    def mobile?
      user_agent.match?(MOBILE_REGEX)
    end

    def tablet?
      user_agent.match?(TABLET_REGEX)
    end
  end
end 