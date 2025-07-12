module Analytics
  class VisitTrackerService
    attr_reader :request, :params, :visitor_uuid

    def initialize(request, params)
      @request = request
      @params = params
      @visitor_uuid = params[:visitor_uuid]
    end

    def call
      visitor = find_or_create_visitor
      visit = create_or_continue_visit(visitor)
      track_page_view(visit)
      
      { visitor_uuid: visitor.uuid, visit_id: visit.id }
    end

    private

    def find_or_create_visitor
      Visitor.find_or_create_from_request(request, visitor_uuid)
    end

    def create_or_continue_visit(visitor)
      recent_visit = find_recent_visit(visitor)
      return recent_visit if recent_visit.present?

      create_new_visit(visitor)
    end

    def find_recent_visit(visitor)
      visitor.visits
            .where('created_at > ?', 30.minutes.ago)
            .order(created_at: :desc)
            .first
    end

    def create_new_visit(visitor)
      geo_data = GeoLocationService.new(request.remote_ip).call

      Visit.create!(
        visitor: visitor,
        page_path: params[:page_path],
        referrer: request.referrer,
        device_type: DeviceDetectorService.new(request.user_agent).device_type,
        source_type: SourceDetectorService.new(request.referrer).source_type,
        country_code: geo_data[:country_code],
        region: geo_data[:region],
        city: geo_data[:city],
        entered_at: Time.current,
        site_url: params[:site_url],
        app_name: params[:app_name]
      )
    end

    def track_page_view(visit)
      PageView.track(visit, params[:page_path])
    end
  end
end 