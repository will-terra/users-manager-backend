require 'rails_helper'
# Ensure the job class is loaded in test environment
require Rails.root.join('app', 'jobs', 'jwt_blacklist_cleanup_job').to_s

RSpec.describe JWTBlacklistCleanupJob, type: :job do
  it 'calls cleanup_expired! on JWTBlacklist' do
    expect(JWTBlacklist).to receive(:cleanup_expired!)
    described_class.perform_now
  end

  it 'logs and raises on error' do
    allow(JWTBlacklist).to receive(:cleanup_expired!).and_raise(StandardError.new('boom'))
    expect(Rails.logger).to receive(:error).at_least(:once)
    expect { described_class.perform_now }.to raise_error(StandardError)
  end
end
