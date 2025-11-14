require 'rails_helper'

RSpec.describe JWTBlacklist, type: :model do
  describe '.revoke_jwt' do
    it 'returns nil when jti missing' do
      expect(described_class.revoke_jwt({}, nil)).to be_nil
    end

    it 'creates a record when jti present' do
      payload = { 'jti' => 'xyz', 'exp' => (Time.now.to_i + 3600) }
      expect { described_class.revoke_jwt(payload, nil) }.to change { described_class.where(jti: 'xyz').count }.by(1)
    end
  end

  describe '.jwt_revoked?' do
    it 'returns true when jti exists' do
      described_class.create!(jti: 'abc', exp: 1.hour.from_now)
      expect(described_class.jwt_revoked?({ 'jti' => 'abc' }, nil)).to be true
    end

    it 'returns false when jti missing' do
      expect(described_class.jwt_revoked?({}, nil)).to be false
    end
  end

  describe '.cleanup_expired!' do
    it 'removes expired entries' do
      described_class.create!(jti: 'old', exp: 1.hour.ago)
      described_class.create!(jti: 'new', exp: 1.hour.from_now)
      described_class.cleanup_expired!
      expect(described_class.where(jti: 'old')).to be_empty
      expect(described_class.where(jti: 'new')).not_to be_empty
    end
  end
end
