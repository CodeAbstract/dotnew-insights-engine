require 'rails_helper'

RSpec.describe Analytics::SourceDetectorService do
  subject { described_class.new(referrer) }

  describe '#source_type' do
    context 'with no referrer' do
      let(:referrer) { nil }
      it { expect(subject.source_type).to eq('direct') }
    end

    context 'with empty referrer' do
      let(:referrer) { '' }
      it { expect(subject.source_type).to eq('direct') }
    end

    context 'with search engine referrers' do
      %w[google bing yahoo duckduckgo baidu yandex].each do |engine|
        context "from #{engine}" do
          let(:referrer) { "https://www.#{engine}.com/search?q=test" }
          it { expect(subject.source_type).to eq('search') }
        end
      end
    end

    context 'with social network referrers' do
      %w[facebook twitter linkedin instagram pinterest reddit youtube tiktok].each do |network|
        context "from #{network}" do
          let(:referrer) { "https://www.#{network}.com/share" }
          it { expect(subject.source_type).to eq('social') }
        end
      end
    end

    context 'with other referrer' do
      let(:referrer) { 'https://example.com' }
      it { expect(subject.source_type).to eq('referral') }
    end
  end
end 