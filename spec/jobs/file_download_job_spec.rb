require 'rails_helper'

RSpec.describe FileDownloadJob, type: :job do
  let(:user_import) { instance_double('UserImport', id: 1, file: double('attacher'), save!: true) }

  before do
    allow(UserImport).to receive(:find).with(1).and_return(user_import)
  end

  it 'attaches file and enqueues UserImportJob when download succeeds' do
    file_hash = { io: StringIO.new('x'), filename: 'f.txt', content_type: 'text/plain' }
    allow_any_instance_of(FileDownloadService).to receive(:call).and_return(file_hash)
    expect(user_import.file).to receive(:attach)
    expect(UserImportJob).to receive(:perform_later).with(1)
    described_class.perform_now(1, 'http://example.com/f.txt')
  end

  it 'marks import as failed when download returns nil' do
    allow_any_instance_of(FileDownloadService).to receive(:call).and_return(nil)
    expect(user_import).to receive(:mark_as_failed)
    described_class.perform_now(1, 'http://example.com/f.txt')
  end
end
require 'rails_helper'

RSpec.describe FileDownloadJob, type: :job do
  include ActiveJob::TestHelper

  let(:user_import) { create(:user_import) }

  it 'enqueues the job' do
    expect {
      FileDownloadJob.perform_later(user_import.id, 'https://example.com/file.csv')
    }.to have_enqueued_job(FileDownloadJob)
  end
end
