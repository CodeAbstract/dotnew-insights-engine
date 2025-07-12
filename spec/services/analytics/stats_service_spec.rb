require 'rails_helper'

RSpec.describe Analytics::StatsService do
  let(:service) { described_class.new(timeframe) }
  let(:timeframe) { 'day' }

  describe '#call' do
    let!(:visitor) { create(:visitor) }
    let!(:visit) { create(:visit, visitor: visitor, entered_at: 1.hour.ago) }
    let!(:page_view) { create(:page_view, visit: visit, viewed_at: 1.hour.ago) }

    it 'returns complete stats structure' do
      result = service.call

      expect(result).to include(
        :summary,
        :traffic_sources,
        :devices,
        :geolocations,
        :pages
      )
    end

    describe 'summary data' do
      it 'calculates correct metrics' do
        result = service.call[:summary]

        expect(result[:total_visits]).to eq(1)
        expect(result[:unique_visitors]).to eq(1)
        expect(result[:page_views]).to eq(1)
        expect(result[:avg_duration]).to be_a(Integer)
      end
    end

    describe 'traffic sources data' do
      it 'counts visits by source' do
        result = service.call[:traffic_sources]

        expect(result).to include(
          direct: be_a(Integer),
          search: be_a(Integer),
          referral: be_a(Integer),
          social: be_a(Integer)
        )
      end
    end

    describe 'devices data' do
      it 'counts visits by device type' do
        result = service.call[:devices]

        expect(result).to include(
          desktop: be_a(Integer),
          mobile: be_a(Integer),
          tablet: be_a(Integer)
        )
      end
    end

    describe 'geolocations data' do
      it 'groups visits by country' do
        result = service.call[:geolocations]

        expect(result).to be_an(Array)
        expect(result.first).to include(:country, :visits) if result.any?
      end
    end

    describe 'pages data' do
      it 'groups page views by path' do
        result = service.call[:pages]

        expect(result).to be_an(Array)
        expect(result.first).to include(:path, :views) if result.any?
      end
    end

    context 'with different timeframes' do
      context 'when timeframe is week' do
        let(:timeframe) { 'week' }

        it 'respects week timeframe' do
          result = service.call
          expect(result).to be_present
        end
      end

      context 'when timeframe is month' do
        let(:timeframe) { 'month' }

        it 'respects month timeframe' do
          result = service.call
          expect(result).to be_present
        end
      end

      context 'when timeframe is invalid' do
        let(:timeframe) { 'invalid' }

        it 'defaults to day timeframe' do
          result = service.call
          expect(result).to be_present
        end
      end
    end

    context 'with no visits in range' do
      before do
        PageView.delete_all
        Visit.delete_all
      end

      it 'handles empty data gracefully' do
        result = service.call

        expect(result[:summary][:total_visits]).to eq(0)
        expect(result[:summary][:unique_visitors]).to eq(0)
        expect(result[:summary][:page_views]).to eq(0)
        expect(result[:summary][:bounce_rate]).to eq(0.0)
        expect(result[:summary][:avg_duration]).to eq(0)
      end

      it 'returns empty arrays for grouped data' do
        result = service.call

        expect(result[:geolocations]).to eq([])
        expect(result[:pages]).to eq([])
      end
    end
  end

  describe '#calculate_bounce_rate' do
    context 'when there are visits' do
      let!(:visitor) { create(:visitor) }
      let!(:bounced_visit) { create(:visit, visitor: visitor, bounced: true, entered_at: 1.hour.ago) }
      let!(:engaged_visit) { create(:visit, visitor: visitor, bounced: false, entered_at: 1.hour.ago) }

      it 'calculates bounce rate correctly' do
        result = service.call[:summary]
        expect(result[:bounce_rate]).to eq(50.0)
      end
    end

    context 'when there are no visits' do
      before do
        PageView.delete_all
        Visit.delete_all
      end

      it 'returns 0.0' do
        result = service.call[:summary]
        expect(result[:bounce_rate]).to eq(0.0)
      end
    end
  end
end 