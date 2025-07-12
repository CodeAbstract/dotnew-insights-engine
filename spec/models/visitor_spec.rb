require 'rails_helper'

RSpec.describe Visitor, type: :model do
  describe 'associations' do
    it { should have_many(:visits) }
  end

  describe 'validations' do
    it { should validate_presence_of(:uuid) }
    it { should validate_uniqueness_of(:uuid) }
    it { should validate_presence_of(:ip_address) }
    it { should validate_presence_of(:user_agent) }
  end

  describe '.find_or_create_from_request' do
    let(:request) do
      double(
        remote_ip: '192.168.1.1',
        ip: '192.168.1.1',
        user_agent: 'Mozilla/5.0'
      )
    end

    context 'when visitor exists' do
      let!(:visitor) { create(:visitor) }

      it 'returns existing visitor' do
        expect(
          described_class.find_or_create_from_request(request, visitor.uuid)
        ).to eq(visitor)
      end
    end

    context 'when visitor does not exist' do
      it 'creates a new visitor' do
        expect {
          described_class.find_or_create_from_request(request)
        }.to change(described_class, :count).by(1)
      end

      it 'sets correct attributes' do
        visitor = described_class.find_or_create_from_request(request)
        expect(visitor.ip_address).to eq('192.168.1.1')
        expect(visitor.user_agent).to eq('Mozilla/5.0')
        expect(visitor.uuid).to be_present
        expect(visitor.first_visit_at).to be_present
      end
    end
  end

  describe 'input sanitization' do
    it 'strips whitespace from user agent' do
      visitor = build(:visitor, user_agent: ' Mozilla/5.0 ')
      visitor.valid?
      expect(visitor.user_agent).to eq('Mozilla/5.0')
    end

    it 'strips whitespace from ip address' do
      visitor = build(:visitor, ip_address: ' 192.168.1.1 ')
      visitor.valid?
      expect(visitor.ip_address).to eq('192.168.1.1')
    end
  end

  describe 'IP address validation' do
    subject { build(:visitor) }

    context 'with valid IPv4 addresses' do
      %w[192.168.1.1 10.0.0.1 172.16.0.1 8.8.8.8].each do |ip|
        it "accepts #{ip}" do
          subject.ip_address = ip
          expect(subject).to be_valid
        end
      end
    end

    context 'with valid IPv6 addresses' do
      %w[2001:0db8:85a3:0000:0000:8a2e:0370:7334 fe80:0000:0000:0000:0202:b3ff:fe1e:8329].each do |ip|
        it "accepts #{ip}" do
          subject.ip_address = ip
          expect(subject).to be_valid
        end
      end
    end

    context 'with invalid IP addresses' do
      [
        '256.1.2.3',        # Invalid IPv4 octet
        '1.2.3.4.5',        # Too many octets
        '1.2.3',            # Too few octets
        'invalid',          # Not an IP
        '300.168.1.1',      # Invalid octet value
        'fe80::1::1',       # Invalid IPv6 format
        '2001:0db8:85a3'    # Incomplete IPv6
      ].each do |ip|
        it "rejects #{ip}" do
          subject.ip_address = ip
          expect(subject).not_to be_valid
          expect(subject.errors[:ip_address]).to include('must be a valid IPv4 or IPv6 address')
        end
      end
    end
  end
end 