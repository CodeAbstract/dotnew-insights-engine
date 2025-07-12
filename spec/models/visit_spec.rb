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

  describe '.determine_device_type' do
    context 'with tablet user agent' do
      it 'returns tablet' do
        user_agent = 'Mozilla/5.0 (iPad; CPU OS 14_0 like Mac OS X)'
        expect(described_class.determine_device_type(user_agent)).to eq('tablet')
      end
    end

    context 'with mobile user agent' do
      it 'returns mobile' do
        user_agent = 'Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X)'
        expect(described_class.determine_device_type(user_agent)).to eq('mobile')
      end
    end

    context 'with desktop user agent' do
      it 'returns desktop' do
        user_agent = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)'
        expect(described_class.determine_device_type(user_agent)).to eq('desktop')
      end
    end
  end

  describe '.determine_source_type' do
    context 'with no referrer' do
      it 'returns direct' do
        expect(described_class.determine_source_type(nil)).to eq('direct')
      end
    end

    context 'with search engine referrer' do
      %w[google bing yahoo baidu duckduckgo yandex].each do |engine|
        it "returns search for #{engine}" do
          referrer = "https://www.#{engine}.com/search"
          expect(described_class.determine_source_type(referrer)).to eq('search')
        end
      end
    end

    context 'with social network referrer' do
      %w[facebook twitter instagram linkedin tiktok pinterest].each do |network|
        it "returns social for #{network}" do
          referrer = "https://www.#{network}.com/share"
          expect(described_class.determine_source_type(referrer)).to eq('social')
        end
      end
    end

    context 'with other referrer' do
      it 'returns referral' do
        expect(described_class.determine_source_type('https://example.com')).to eq('referral')
      end
    end
  end

  describe 'duration calculations' do
    let(:visit) { create(:visit, entered_at: Time.current) }

    describe '#duration_in_seconds' do
      it 'returns 0 when not exited' do
        expect(visit.duration_in_seconds).to eq(0)
      end

      it 'calculates duration when exited' do
        visit.update(exited_at: 5.minutes.from_now)
        expect(visit.duration_in_seconds).to eq(300)
      end
    end

    describe '#mark_as_exited' do
      it 'sets exited_at to current time' do
        Timecop.freeze do
          visit.mark_as_exited
          expect(visit.exited_at).to eq(Time.current)
        end
      end

      it 'updates duration' do
        Timecop.freeze do
          visit.mark_as_exited
          expect(visit.duration).to eq(0)
        end
      end
    end

    describe '#update_duration' do
      it 'updates duration based on current exit time' do
        visit.update(exited_at: 10.minutes.from_now)
        visit.update_duration
        expect(visit.duration).to eq(600)
      end
    end

    describe 'callbacks' do
      describe 'before_save :set_duration' do
        it 'sets duration when exited_at changes' do
          visit.update(exited_at: 15.minutes.from_now)
          expect(visit.duration).to eq(900)
        end

        it 'does not set duration when exited_at is nil' do
          visit.update(page_path: '/new-path')
          expect(visit.duration).to be_nil
        end
      end

      describe 'before_save :update_bounce_status' do
        it 'sets bounced true when page_views_count is 1' do
          visit.update(page_views_count: 1)
          expect(visit.bounced).to be true
        end

        it 'sets bounced false when page_views_count is greater than 1' do
          visit.update(page_views_count: 2)
          expect(visit.bounced).to be false
        end

        it 'does not change bounced when page_views_count does not change' do
          visit.update(bounced: true)
          visit.update(page_path: '/new-path')
          expect(visit.bounced).to be true
        end
      end
    end
  end
end 