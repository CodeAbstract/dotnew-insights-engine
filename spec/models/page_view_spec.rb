require 'rails_helper'

RSpec.describe PageView, type: :model do
  describe 'associations' do
    it { should belong_to(:visit).counter_cache(true) }
  end

  describe 'validations' do
    it { should validate_presence_of(:path) }
    it { should validate_presence_of(:viewed_at) }
  end

  describe 'scopes' do
    let!(:page_view1) { create(:page_view, path: '/home', viewed_at: 1.hour.ago) }
    let!(:page_view2) { create(:page_view, path: '/about', viewed_at: 2.hours.ago) }
    let!(:page_view3) { create(:page_view, path: '/home', viewed_at: 30.minutes.ago) }

    describe '.most_viewed' do
      it 'returns paths ordered by view count' do
        result = described_class.most_viewed
        expect(result['/home']).to eq(2)
        expect(result['/about']).to eq(1)
      end
    end

    describe '.recent' do
      it 'returns page views ordered by viewed_at desc' do
        expect(described_class.recent).to eq([page_view3, page_view1, page_view2])
      end
    end

    describe '.of_path' do
      it 'returns page views for specific path' do
        expect(described_class.of_path('/home')).to contain_exactly(page_view1, page_view3)
      end
    end
  end

  describe '.track' do
    let(:visit) { create(:visit) }
    let(:path) { '/test-path' }

    it 'creates a new page view' do
      expect {
        described_class.track(visit, path)
      }.to change(described_class, :count).by(1)
    end

    it 'sets correct attributes' do
      Timecop.freeze do
        page_view = described_class.track(visit, path)
        expect(page_view.visit).to eq(visit)
        expect(page_view.path).to eq(path)
        expect(page_view.viewed_at).to eq(Time.current)
      end
    end

    it 'increments visit page_views_count' do
      expect {
        described_class.track(visit, path)
      }.to change { visit.reload.page_views_count }.by(1)
    end
  end
end 