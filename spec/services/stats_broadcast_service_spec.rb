require 'rails_helper'

RSpec.describe StatsBroadcastService, type: :service do
  describe '.broadcast_stats_update' do
    it 'broadcasts stats to admin_stats channel' do
      expect(ActionCable.server).to receive(:broadcast).with(
        'admin_stats',
        hash_including(type: 'stats_update')
      )

      StatsBroadcastService.broadcast_stats_update
    end
  end
end
