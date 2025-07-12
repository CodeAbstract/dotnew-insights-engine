require 'rails_helper'

RSpec.describe Analytics::GeoLocationService do
  subject { described_class.new(ip_address) }

  describe '#call' do
    context 'with blank IP' do
      let(:ip_address) { nil }
      
      it 'returns default location' do
        expect(subject.call).to eq({
          country_code: 'UN',
          region: 'Unknown',
          city: 'Unknown'
        })
      end
    end

    context 'with local IP addresses' do
      %w[localhost 127.0.0.1 ::1 192.168.1.1 10.0.0.1 172.16.0.1].each do |ip|
        context "with #{ip}" do
          let(:ip_address) { ip }
          
          it 'returns default location' do
            expect(subject.call).to eq({
              country_code: 'UN',
              region: 'Unknown',
              city: 'Unknown'
            })
          end
        end
      end
    end

    context 'with valid IP address' do
      let(:ip_address) { '8.8.8.8' }
      let(:mock_result) do
        {
          'country' => { 'iso_code' => 'US' },
          'subdivisions' => [{ 'name' => 'California' }],
          'city' => { 'name' => 'Mountain View' }
        }
      end
      let(:mock_client) { instance_double(MaxMind::DB) }

      before do
        allow(MaxMind::DB).to receive(:new).and_return(mock_client)
        allow(mock_client).to receive(:get).with(ip_address).and_return(mock_result)
      end

      it 'returns location data' do
        expect(subject.call).to eq({
          country_code: 'US',
          region: 'California',
          city: 'Mountain View'
        })
      end
    end

    context 'when GeoIP lookup fails' do
      let(:ip_address) { '8.8.8.8' }
      
      before do
        allow(MaxMind::DB).to receive(:new)
          .and_raise(StandardError.new('GeoIP database error'))
      end

      it 'returns default location and logs error' do
        expect(Rails.logger).to receive(:error)
          .with('GeoIP lookup failed: GeoIP database error')
        
        expect(subject.call).to eq({
          country_code: 'UN',
          region: 'Unknown',
          city: 'Unknown'
        })
      end
    end
  end
end 