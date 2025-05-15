require 'rails_helper'

RSpec.describe Analytics::VisitTrackerService do
  let(:request) do
    double(
      remote_ip: '192.168.1.1',
      ip: '192.168.1.1',
      user_agent: 'Mozilla/5.0',
      referrer: 'https://google.com'
    )
  end

  let(:params) do
    {
      visitor_uuid: nil,
      page_path: '/test-page'
    }
  end

  subject { described_class.new(request, params) }

  describe '#call' do
    context 'with new visitor' do
      it 'creates a new visitor and visit' do
        expect {
          subject.call
        }.to change(Visitor, :count).by(1)
         .and change(Visit, :count).by(1)
         .and change(PageView, :count).by(1)
      end

      it 'returns visitor uuid and visit id' do
        result = subject.call
        expect(result).to include(:visitor_uuid, :visit_id)
      end
    end

    context 'with existing visitor' do
      let!(:visitor) { create(:visitor) }
      let(:params) { { visitor_uuid: visitor.uuid, page_path: '/test-page' } }

      context 'with recent visit' do
        let!(:recent_visit) do
          create(:visit, visitor: visitor, created_at: 15.minutes.ago)
        end

        it 'uses existing visit' do
          expect {
            subject.call
          }.not_to change(Visit, :count)
        end

        it 'adds page view to existing visit' do
          expect {
            subject.call
          }.to change(PageView, :count).by(1)
        end
      end

      context 'without recent visit' do
        let!(:old_visit) do
          create(:visit, visitor: visitor, created_at: 1.hour.ago)
        end

        it 'creates new visit' do
          expect {
            subject.call
          }.to change(Visit, :count).by(1)
        end
      end
    end
  end
end 