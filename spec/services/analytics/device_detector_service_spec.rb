require 'rails_helper'

RSpec.describe Analytics::DeviceDetectorService do
  subject { described_class.new(user_agent) }

  describe '#device_type' do
    context 'with blank user agent' do
      let(:user_agent) { nil }
      it { expect(subject.device_type).to eq('unknown') }
    end

    context 'with desktop user agent' do
      let(:user_agent) { 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)' }
      it { expect(subject.device_type).to eq('desktop') }
    end

    context 'with mobile user agent' do
      let(:user_agent) { 'Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X)' }
      it { expect(subject.device_type).to eq('mobile') }
    end

    context 'with tablet user agent' do
      let(:user_agent) { 'Mozilla/5.0 (iPad; CPU OS 14_0 like Mac OS X)' }
      it { expect(subject.device_type).to eq('tablet') }
    end
  end
end 