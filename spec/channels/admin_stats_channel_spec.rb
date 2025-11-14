require 'rails_helper'

RSpec.describe AdminStatsChannel, type: :channel do
  let(:admin) { create(:user, :admin) }
  let(:user) { create(:user) }

  before do
    stub_connection current_user: admin
  end

  it 'successfully subscribes admin user' do
    subscribe
    expect(subscription).to be_confirmed
    expect(subscription).to have_stream_from('admin_stats')
  end

  it 'rejects non-admin user' do
    stub_connection current_user: user
    subscribe
    expect(subscription).to be_rejected
  end

  it 'transmits stats when requested' do
    subscribe
    perform :request_stats
    expect(transmissions.last).to include(
      'type' => 'stats_update',
      'data' => hash_including('total_users', 'admin_count')
    )
  end
end
