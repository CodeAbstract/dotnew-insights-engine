require 'rails_helper'

RSpec.describe Api::V1::AnalyticsController, type: :controller do
  let(:visitor) { create(:visitor) }
  let(:visit) { create(:visit, visitor: visitor) }

  before do
    allow(controller).to receive(:geo_locate).and_return({
      country_code: 'US',
      region: 'California',
      city: 'San Francisco'
    })
  end

  describe 'POST #track' do
    context 'with valid parameters' do
      let(:valid_params) do
        {
          visitor_uuid: visitor.uuid,
          page_path: '/home'
        }
      end

      before do
        allow(Analytics::VisitTrackerService).to receive(:new).and_return(
          double(call: { visitor_uuid: visitor.uuid, visit_id: visit.id })
        )
      end

      it 'returns success' do
        post :track, params: valid_params
        expect(response).to have_http_status(:ok)
      end

      it 'returns visitor uuid and visit id' do
        post :track, params: valid_params
        json = JSON.parse(response.body)
        expect(json['visitor_uuid']).to eq(visitor.uuid)
        expect(json['visit_id']).to eq(visit.id)
      end

      context 'with existing visitor' do
        it 'uses existing visitor' do
          post :track, params: valid_params
          expect(response).to have_http_status(:ok)
        end
      end
    end

    context 'with invalid parameters' do
      let(:invalid_params) do
        { visitor_uuid: visitor.uuid }
        # Missing page_path
      end

      it 'returns unprocessable entity status' do
        post :track, params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns error message' do
        post :track, params: invalid_params
        json = JSON.parse(response.body)
        expect(json['error']).to eq('page_path is required')
      end
    end
  end

  describe 'POST #end_visit' do
    context 'with valid visit_id' do
      it 'ends the visit' do
        post :end_visit, params: { visit_id: visit.id }
        expect(response).to have_http_status(:ok)
        expect(visit.reload.exited_at).to be_present
      end
    end

    context 'with invalid visit_id' do
      it 'returns not found status' do
        post :end_visit, params: { visit_id: 99999 }
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'GET #stats' do
    context 'without timeframe parameter' do
      it 'returns stats with default timeframe' do
        allow(Analytics::StatsService).to receive(:new).and_return(
          double(call: { summary: {}, traffic_sources: {}, devices: {}, geolocations: [], pages: [] })
        )

        get :stats
        expect(response).to have_http_status(:ok)
      end
    end

    context 'with timeframe parameter' do
      it 'returns stats for specified timeframe' do
        allow(Analytics::StatsService).to receive(:new).and_return(
          double(call: { summary: {}, traffic_sources: {}, devices: {}, geolocations: [], pages: [] })
        )

        get :stats, params: { timeframe: 'week' }
        expect(response).to have_http_status(:ok)
      end
    end

    context 'when error occurs' do
      it 'handles error gracefully' do
        allow(Analytics::StatsService).to receive(:new).and_raise(StandardError, 'Test error')
        
        get :stats
        expect(response).to have_http_status(:internal_server_error)
      end
    end
  end

  describe 'private methods' do
    describe '#create_or_continue_visit' do
      let(:visitor) { create(:visitor) }
      let(:request) { double('request', referrer: 'https://google.com', remote_ip: '192.168.1.1', user_agent: 'Mozilla/5.0') }

      before do
        allow(controller).to receive(:request).and_return(request)
        allow(controller).to receive(:params).and_return({ page_path: '/test' })
        allow(Visit).to receive(:determine_device_type).and_return('desktop')
        allow(Visit).to receive(:determine_source_type).and_return('search')
      end

      context 'with recent visit' do
        let!(:recent_visit) { create(:visit, visitor: visitor, created_at: 10.minutes.ago) }

        it 'returns the recent visit' do
          result = controller.send(:create_or_continue_visit, visitor)
          expect(result).to eq(recent_visit)
        end
      end

      context 'without recent visit' do
        it 'creates a new visit' do
          expect {
            controller.send(:create_or_continue_visit, visitor)
          }.to change(Visit, :count).by(1)
        end
      end
    end

    describe '#calculate_bounce' do
      let(:visit) { create(:visit) }

      it 'updates bounce status based on page views' do
        create(:page_view, visit: visit)
        controller.send(:calculate_bounce, visit)
        expect(visit.reload.bounced).to be true
      end
    end

    describe '#time_range' do
      it 'returns correct range for day' do
        result = controller.send(:time_range, 'day')
        expect(result).to be_a(Range)
      end

      it 'returns correct range for week' do
        result = controller.send(:time_range, 'week')
        expect(result).to be_a(Range)
      end

      it 'returns correct range for month' do
        result = controller.send(:time_range, 'month')
        expect(result).to be_a(Range)
      end

      it 'returns correct range for year' do
        result = controller.send(:time_range, 'year')
        expect(result).to be_a(Range)
      end

      it 'defaults to day for invalid timeframe' do
        result = controller.send(:time_range, 'invalid')
        expect(result).to be_a(Range)
      end
    end

    describe '#track_params' do
      it 'permits visitor_uuid and page_path' do
        allow(controller).to receive(:params).and_return(
          ActionController::Parameters.new(visitor_uuid: 'test', page_path: '/test', other: 'ignored')
        )
        
        result = controller.send(:track_params)
        expect(result[:visitor_uuid]).to eq('test')
        expect(result[:page_path]).to eq('/test')
        expect(result[:other]).to be_nil
      end
    end

    describe '#stats_params' do
      it 'permits timeframe' do
        allow(controller).to receive(:params).and_return(
          ActionController::Parameters.new(timeframe: 'week', other: 'ignored')
        )
        
        result = controller.send(:stats_params)
        expect(result[:timeframe]).to eq('week')
        expect(result[:other]).to be_nil
      end
    end

    describe '#validate_tracking_params' do
      context 'when page_path is present' do
        before do
          allow(controller).to receive(:track_params).and_return({ page_path: '/test' })
        end

        it 'returns nil' do
          result = controller.send(:validate_tracking_params)
          expect(result).to be_nil
        end
      end

      context 'when page_path is missing' do
        before do
          allow(controller).to receive(:track_params).and_return({})
          allow(controller).to receive(:render)
        end

        it 'renders error' do
          expect(controller).to receive(:render).with(
            hash_including(
              json: hash_including(error: 'page_path is required'),
              status: :unprocessable_entity
            )
          )
          controller.send(:validate_tracking_params)
        end
      end
    end

    describe '#geo_locate' do
      it 'returns default location data' do
        result = controller.send(:geo_locate, '192.168.1.1')
        expect(result).to include(:country_code, :region, :city)
      end
    end

    describe '#summary_data' do
      let(:timeframe) { 'day' }
      let!(:visit) { create(:visit, entered_at: 1.hour.ago) }

      it 'returns summary statistics for timeframe' do
        result = controller.send(:summary_data, timeframe)
        expect(result).to include(:total_visits, :unique_visitors, :page_views, :bounce_rate, :avg_duration)
      end
    end

    describe '#traffic_sources_data' do
      let(:timeframe) { 'day' }

      it 'returns traffic source counts for timeframe' do
        result = controller.send(:traffic_sources_data, timeframe)
        expect(result).to include(:direct, :search, :referral, :social)
      end
    end

    describe '#devices_data' do
      let(:timeframe) { 'day' }

      it 'returns device type counts for timeframe' do
        result = controller.send(:devices_data, timeframe)
        expect(result).to include(:desktop, :mobile, :tablet)
      end
    end

    describe '#geolocations_data' do
      let(:timeframe) { 'day' }

      it 'returns country visit counts for timeframe' do
        result = controller.send(:geolocations_data, timeframe)
        expect(result).to be_an(Array)
      end
    end

    describe '#pages_data' do
      let(:timeframe) { 'day' }

      it 'returns page view counts for timeframe' do
        result = controller.send(:pages_data, timeframe)
        expect(result).to be_an(Array)
      end
    end
  end
end 