module Analytics
  class StatsService
    attr_reader :timeframe

    def initialize(timeframe = 'day')
      @timeframe = timeframe
    end

    def call
      {
        summary: summary_data,
        traffic_sources: traffic_sources_data,
        devices: devices_data,
        geolocations: geolocations_data,
        pages: pages_data
      }
    end

    private

    def time_range
      case timeframe
      when 'week'  then 1.week.ago..Time.current
      when 'month' then 1.month.ago..Time.current
      when 'year'  then 1.year.ago..Time.current
      else              1.day.ago..Time.current
      end
    end

    def visits_in_range
      @visits_in_range ||= Visit.where(entered_at: time_range)
    end

    def summary_data
      {
        total_visits: visits_in_range.count,
        unique_visitors: visits_in_range.select(:visitor_id).distinct.count,
        page_views: PageView.joins(:visit)
                          .where(visits: { entered_at: time_range })
                          .count,
        bounce_rate: calculate_bounce_rate,
        avg_duration: visits_in_range.average(:duration).to_i
      }
    end

    def traffic_sources_data
      {
        direct: visits_in_range.from_direct.count,
        search: visits_in_range.from_search.count,
        referral: visits_in_range.from_referral.count,
        social: visits_in_range.from_social.count
      }
    end

    def devices_data
      {
        desktop: visits_in_range.from_desktop.count,
        mobile: visits_in_range.from_mobile.count,
        tablet: visits_in_range.from_tablet.count
      }
    end

    def geolocations_data
      visits_in_range
        .group(:country_code)
        .order(count_all: :desc)
        .count
        .map { |country, count| { country: country, visits: count } }
    end

    def pages_data
      PageView.joins(:visit)
             .where(visits: { entered_at: time_range })
             .group(:path)
             .order(count_all: :desc)
             .count
             .map { |path, count| { path: path, views: count } }
    end

    def calculate_bounce_rate
      total = visits_in_range.count
      return 0.0 if total.zero?

      (visits_in_range.bounced.count.to_f / total * 100).round(2)
    end
  end
end 