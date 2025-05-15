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
end 