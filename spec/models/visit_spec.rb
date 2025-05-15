require 'rails_helper'

RSpec.describe Visit, type: :model do
  describe 'associations' do
    it { should belong_to(:visitor) }
    it { should have_many(:page_views).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:page_path) }
    it { should validate_presence_of(:entered_at) }
  end

  describe 'scopes' do
    let!(:bounced_visit) { create(:visit, :bounced) }
    let!(:engaged_visit) { create(:visit, :engaged) }
    let!(:in_progress_visit) { create(:visit) }
    let!(:desktop_visit) { create(:visit, device_type: 'desktop') }
    let!(:mobile_visit) { create(:visit, device_type: 'mobile') }
    let!(:direct_visit) { create(:visit, source_type: 'direct') }
    let!(:search_visit) { create(:visit, source_type: 'search') }

    it 'filters bounced visits' do
      expect(described_class.bounced).to include(bounced_visit)
      expect(described_class.bounced).not_to include(engaged_visit)
    end

    it 'filters engaged visits' do
      expect(described_class.engaged).to include(engaged_visit)
      expect(described_class.engaged).not_to include(bounced_visit)
    end

    it 'filters in-progress visits' do
      expect(described_class.in_progress).to include(in_progress_visit)
      expect(described_class.in_progress).not_to include(bounced_visit)
    end

    it 'filters by device type' do
      expect(described_class.from_desktop).to include(desktop_visit)
      expect(described_class.from_mobile).to include(mobile_visit)
    end

    it 'filters by source type' do
      expect(described_class.from_direct).to include(direct_visit)
      expect(described_class.from_search).to include(search_visit)
    end
  end

  describe '#bounce?' do
    it 'returns true for visits with one page view' do
      visit = create(:visit, page_views_count: 1)
      expect(visit).to be_bounce
    end

    it 'returns false for visits with multiple page views' do
      visit = create(:visit, page_views_count: 2)
      expect(visit).not_to be_bounce
    end
  end

  describe '#end_visit' do
    let(:visit) { create(:visit) }

    it 'sets exited_at and duration' do
      Timecop.freeze do
        visit.end_visit
        expect(visit.exited_at).to eq(Time.current)
        expect(visit.duration).to eq((visit.exited_at - visit.entered_at).to_i)
      end
    end

    it 'does not update if already ended' do
      visit.update(exited_at: 1.hour.ago)
      original_exit_time = visit.exited_at
      visit.end_visit
      expect(visit.exited_at).to eq(original_exit_time)
    end
  end
end 