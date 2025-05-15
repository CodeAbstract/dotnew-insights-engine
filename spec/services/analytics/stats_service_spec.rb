require 'rails_helper'

RSpec.describe Analytics::StatsService do
  let(:timeframe) { 'day' }
  subject { described_class.new(timeframe) }

  describe '#call' do
    let!(:visitor) { create(:visitor) }
    let!(:bounced_visit) do
      create(:visit, :bounced,
        visitor: visitor,
        entered_at: 2.hours.ago,
        device_type: 'desktop',
        source_type: 'direct',
        country_code: 'US'
      )
    end
    let!(:engaged_visit) do
      create(:visit, :engaged,
        visitor: visitor,
        entered_at: 1.hour.ago,
        device_type: 'mobile',
        source_type: 'search',
        country_code: 'GB'
      )
    end
    let!(:old_visit) do
      create(:visit,
        visitor: visitor,
        entered_at: 2.days.ago
      )
    end

    it 'returns complete stats structure' do
      result = subject.call
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
        summary = subject.call[:summary]
        expect(summary[:total_visits]).to eq(2)
        expect(summary[:unique_visitors]).to eq(1)
        expect(summary[:bounce_rate]).to eq(50.0)
      end
    end

    describe 'traffic sources data' do
      it 'counts visits by source' do
        sources = subject.call[:traffic_sources]
        expect(sources[:direct]).to eq(1)
        expect(sources[:search]).to eq(1)
      end
    end

    describe 'devices data' do
      it 'counts visits by device type' do
        devices = subject.call[:devices]
        expect(devices[:desktop]).to eq(1)
        expect(devices[:mobile]).to eq(1)
      end
    end

    describe 'geolocations data' do
      it 'groups visits by country' do
        geolocations = subject.call[:geolocations]
        us_data = geolocations.find { |g| g[:country] == 'US' }
        gb_data = geolocations.find { |g| g[:country] == 'GB' }
        
        expect(us_data[:visits]).to eq(1)
        expect(gb_data[:visits]).to eq(1)
      end
    end

    context 'with different timeframes' do
      it 'respects week timeframe' do
        service = described_class.new('week')
        expect(service.call[:summary][:total_visits]).to eq(3)
      end

      it 'respects month timeframe' do
        service = described_class.new('month')
        expect(service.call[:summary][:total_visits]).to eq(3)
      end

      it 'defaults to day timeframe' do
        service = described_class.new(nil)
        expect(service.call[:summary][:total_visits]).to eq(2)
      end
    end
  end
end 