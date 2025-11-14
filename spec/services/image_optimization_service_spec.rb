require 'rails_helper'

RSpec.describe ImageOptimizationService do
  describe '.optimize_avatar' do
    it 'returns nil when blob is not an image' do
      blob = double('blob', image?: false)
      expect(described_class.optimize_avatar(blob)).to be_nil
    end

    it 'processes variants when blob is an image' do
      blob = double('blob', image?: true, filename: 'avatar.png')
      expect(Rails.logger).to receive(:info).with(/Processing variants for avatar:/)
      described_class.optimize_avatar(blob)
    end
  end
end
