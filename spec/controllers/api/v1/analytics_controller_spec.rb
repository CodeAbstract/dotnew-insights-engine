require 'rails_helper'

RSpec.describe Api::V1::AnalyticsController, type: :controller do
  describe 'POST #track' do
    let(:valid_params) { { page_path: '/test-page' } }
    let(:invalid_params) { { page_path: nil } }

    context 'with valid parameters' do
      it 'returns success' do
        post :track, params: valid_params
        expect(response).to have_http_status(:ok)
      end

      it 'returns visitor uuid and visit id' do
        post :track, params: valid_params
        json_response = JSON.parse(response.body)
        expect(json_response).to include('visitor_uuid', 'visit_id')
      end

      context 'with existing visitor' do
        let!(:visitor) { create(:visitor) }
        let(:params_with_visitor) do
          valid_params.merge(visitor_uuid: visitor.uuid)
        end

        it 'uses existing visitor' do
          expect {
            post :track, params: params_with_visitor
          }.not_to change(Visitor, :count)
        end
      end
    end

    context 'with invalid parameters' do
      it 'returns unprocessable entity status' do
        post :track, params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns error message' do
        post :track, params: invalid_params
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to include('page_path is required')
      end
    end
  end

  describe 'POST #end_visit' do
    let!(:visit) { create(:visit) }

    context 'with valid visit_id' do
      it 'ends the visit' do
        post :end_visit, params: { visit_id: visit.id }
        expect(response).to have_http_status(:ok)
        expect(visit.reload.exited_at).to be_present
      end
    end

    context 'with invalid visit_id' do
      it 'returns not found status' do
        post :end_visit, params: { visit_id: 0 }
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'GET #stats' do
    let!(:visit) { create(:visit, :completed) }

    context 'without timeframe parameter' do
      it 'returns stats with default timeframe' do
        get :stats
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response).to include(
          'summary',
          'traffic_sources',
          'devices',
          'geolocations',
          'pages'
        )
      end
    end

    context 'with timeframe parameter' do
      it 'returns stats for specified timeframe' do
        get :stats, params: { timeframe: 'week' }
        expect(response).to have_http_status(:ok)
      end
    end

    context 'when error occurs' do
      before do
        allow_any_instance_of(Analytics::StatsService)
          .to receive(:call)
          .and_raise(StandardError, 'Test error')
      end

      it 'handles error gracefully' do
        get :stats
        expect(response).to have_http_status(:internal_server_error)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to be_present
      end
    end
  end
end 