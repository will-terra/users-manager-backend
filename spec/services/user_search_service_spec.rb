require 'rails_helper'

RSpec.describe UserSearchService do
  let!(:admin) { create(:user, full_name: 'Admin Person', email: 'admin@example.com', role: 'admin') }
  let!(:user1) { create(:user, full_name: 'Alice Example', email: 'alice@example.com') }
  let!(:user2) { create(:user, full_name: 'Bob Example', email: 'bob@example.com') }

  it 'filters by role' do
    result = described_class.new(User.all, { role: 'admin' }).call
    expect(result).to include(admin)
    expect(result).not_to include(user1)
  end

  it 'filters by search term' do
    result = described_class.new(User.all, { search: 'Alice' }).call
    expect(result).to include(user1)
    expect(result).not_to include(user2)
  end

  it 'filters by date range' do
    user_old = create(:user, created_at: 10.days.ago)
    result = described_class.new(User.all, { start_date: 15.days.ago.to_s, end_date: 5.days.ago.to_s }).call
    expect(result).to include(user_old)
  end
end
