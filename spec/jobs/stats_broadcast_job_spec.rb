require 'rails_helper'

RSpec.describe StatsBroadcastJob, type: :job do
  include ActiveJob::TestHelper

  it 'enqueues the job' do
    expect {
      StatsBroadcastJob.perform_later
    }.to have_enqueued_job(StatsBroadcastJob)
  end

  it 'calls the broadcast service' do
    expect(StatsBroadcastService).to receive(:broadcast_stats_update)

    perform_enqueued_jobs do
      StatsBroadcastJob.perform_later
    end
  end
end
