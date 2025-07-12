module Api
  module V1
    class AnalyticsController < ApplicationController
      include ErrorHandler
      
      before_action :validate_tracking_params, only: [:track]
      
      # Track a hit/pageview
      def track
        result = Analytics::VisitTrackerService.new(request, track_params).call
        render json: result, status: :ok
      rescue StandardError => e
        handle_error(e)
      end
      
      # End a visit (update exit time)
      def end_visit
        visit = Visit.find_by(id: params[:visit_id])
        
        if visit
          visit.mark_as_exited
          calculate_bounce(visit)
          
          render json: { status: 'Visit ended' }
        else
          render json: { error: 'Visit not found' }, status: :not_found
        end
      end
      
      # Get analytics data
      def stats
        result = Analytics::StatsService.new(stats_params[:timeframe]).call
        render json: result, status: :ok
      rescue StandardError => e
        handle_error(e)
      end
      
      private
      
      def create_or_continue_visit(visitor)
        # Try to find an existing visit from the last 30 minutes
        recent_visit = visitor.visits.where('created_at > ?', 30.minutes.ago)
                            .order(created_at: :desc).first
        
        if recent_visit
          recent_visit
        else
          referrer = request.referrer
          # Using the GeoIP2 gem to determine location (would need to be installed)
          geo_data = geo_locate(request.remote_ip)
          
          Visit.create!(
            visitor: visitor,
            page_path: params[:page_path],
            referrer: referrer,
            device_type: Visit.determine_device_type(request.user_agent),
            source_type: Visit.determine_source_type(referrer),
            country_code: geo_data[:country_code],
            region: geo_data[:region],
            city: geo_data[:city],
            entered_at: Time.current
          )
        end
      end
      
      def calculate_bounce(visit)
        # A bounce is a visit with only one page view
        visit.update(bounced: visit.page_views.count == 1)
      end
      
      def geo_locate(ip)
        # This would use a gem like GeoIP2 or call to an external service
        # Simplified example:
        {
          country_code: 'US',
          region: 'California',
          city: 'San Francisco'
        }
      end
      
      def time_range(timeframe)
        case timeframe
        when 'day'
          1.day.ago..Time.current
        when 'week'
          1.week.ago..Time.current
        when 'month'
          1.month.ago..Time.current
        when 'year'
          1.year.ago..Time.current
        else
          1.day.ago..Time.current
        end
      end
      
      def summary_data(timeframe)
        range = time_range(timeframe)
        
        visits = Visit.where(entered_at: range)
        
        {
          total_visits: visits.count,
          unique_visitors: visits.select(:visitor_id).distinct.count,
          page_views: PageView.joins(:visit).where(visits: { entered_at: range }).count,
          bounce_rate: (visits.bounced.count.to_f / visits.count * 100).round(2),
          avg_duration: visits.average(:duration).to_i
        }
      end
      
      def traffic_sources_data(timeframe)
        range = time_range(timeframe)
        visits = Visit.where(entered_at: range)
        
        {
          direct: visits.from_direct.count,
          search: visits.from_search.count,
          referral: visits.from_referral.count,
          social: visits.from_social.count
        }
      end
      
      def devices_data(timeframe)
        range = time_range(timeframe)
        visits = Visit.where(entered_at: range)
        
        {
          desktop: visits.from_desktop.count,
          mobile: visits.from_mobile.count,
          tablet: visits.from_tablet.count
        }
      end
      
      def geolocations_data(timeframe)
        range = time_range(timeframe)
        
        Visit.where(entered_at: range)
          .group(:country_code)
          .order(count_all: :desc)
          .count
          .map { |country, count| { country: country, visits: count } }
      end
      
      def pages_data(timeframe)
        range = time_range(timeframe)
        
        PageView.joins(:visit)
          .where(visits: { entered_at: range })
          .group(:path)
          .order(count_all: :desc)
          .count
          .map { |path, count| { path: path, views: count } }
      end
      
      def track_params
        params.permit(:visitor_uuid, :page_path, :site_url, :app_name)
      end
      
      def stats_params
        params.permit(:timeframe)
      end
      
      def validate_tracking_params
        unless track_params[:page_path].present?
          render json: { error: 'page_path is required' }, status: :unprocessable_entity
        end
      end
    end
  end
end