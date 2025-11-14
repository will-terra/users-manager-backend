require 'rails_helper'

RSpec.describe UserImportJob, type: :job do
  let(:user) { create(:user) }

  before do
    allow(ActionCable.server).to receive(:broadcast)
  end

  it 'processes CSV import and creates users' do
    user_import = create(:user_import)

    expect { described_class.perform_now(user_import.id) }.to change { User.count }.by(4)

    user_import.reload
    expect(user_import.status).to eq('completed')
    expect(user_import.total_rows).to eq(4)
    expect(ActionCable.server).to have_received(:broadcast).at_least(:once)
  end

  # Unsupported file type handling is validated by model-level file validations
  # and end-to-end behavior is covered by other integration tests.

  it 'records errors when rows are invalid but completes' do
    csv = "full_name,email\nMissingEmail,\n"
    ui = create(:user_import)
    ui.file.detach
    ui.file.attach(io: StringIO.new(csv), filename: 'bad.csv', content_type: 'text/csv')
    ui.save!

    described_class.perform_now(ui.id)
    ui.reload
    expect(ui.status).to eq('completed')
    expect(ui.error_message).to be_present
    expect(ui.error_message).to match(/Email is required/)
  end

  it 'updates existing user when email already exists' do
    # Create an existing user
    existing_user = create(:user, email: 'john@example.com', full_name: 'Old Name', role: 'user')

    # Create CSV with the same email but different attributes
    csv = "full_name,email,role\nJohn Updated,john@example.com,admin\n"
    ui = create(:user_import)
    ui.file.detach
    ui.file.attach(io: StringIO.new(csv), filename: 'update.csv', content_type: 'text/csv')
    ui.save!

    # Should not create a new user, just update the existing one
    expect { described_class.perform_now(ui.id) }.not_to change { User.count }

    ui.reload
    expect(ui.status).to eq('completed')

    # Verify user was updated
    existing_user.reload
    expect(existing_user.full_name).to eq('John Updated')
    expect(existing_user.role).to eq('admin')
    expect(existing_user.email).to eq('john@example.com') # Email should remain the same
  end

  it 'updates password when provided in CSV for existing user' do
    # Create an existing user with a known password
    existing_user = create(:user, email: 'test@example.com', password: 'oldpassword123', password_confirmation: 'oldpassword123')
    old_password_digest = existing_user.encrypted_password

    # Create CSV with new password
    csv = "full_name,email,password\nTest User,test@example.com,newpassword456\n"
    ui = create(:user_import)
    ui.file.detach
    ui.file.attach(io: StringIO.new(csv), filename: 'password_update.csv', content_type: 'text/csv')
    ui.save!

    described_class.perform_now(ui.id)

    ui.reload
    expect(ui.status).to eq('completed')

    # Verify password was updated
    existing_user.reload
    expect(existing_user.encrypted_password).not_to eq(old_password_digest)
    expect(existing_user.valid_password?('newpassword456')).to be true
  end

  it 'does not update password for existing user when not provided in CSV' do
    # Create an existing user with a known password
    existing_user = create(:user, email: 'test2@example.com', password: 'mypassword123', password_confirmation: 'mypassword123')
    old_password_digest = existing_user.encrypted_password

    # Create CSV without password field
    csv = "full_name,email,role\nTest User Updated,test2@example.com,admin\n"
    ui = create(:user_import)
    ui.file.detach
    ui.file.attach(io: StringIO.new(csv), filename: 'no_password_update.csv', content_type: 'text/csv')
    ui.save!

    described_class.perform_now(ui.id)

    ui.reload
    expect(ui.status).to eq('completed')

    # Verify password was NOT updated
    existing_user.reload
    expect(existing_user.encrypted_password).to eq(old_password_digest)
    expect(existing_user.valid_password?('mypassword123')).to be true
  end

  it 'sends welcome email with generated password for new users' do
    # CSV with a new user without password -> should generate one and email it
    csv = "full_name,email\nGenerated User,gen@example.com\n"
    ui = create(:user_import)
    ui.file.detach
    ui.file.attach(io: StringIO.new(csv), filename: 'gen_pass.csv', content_type: 'text/csv')
    ui.save!

    # Expect welcome email to be enqueued
    expect {
      described_class.perform_now(ui.id)
    }.to have_enqueued_job(ActionMailer::MailDeliveryJob).with(
      'UserMailer',
      'welcome_email_with_password',
      'deliver_now',
      hash_including(args: [ kind_of(User), kind_of(String) ])
    )

    ui.reload
    expect(ui.status).to eq('completed')
    # Password should NOT be stored
    expect(ui).not_to respond_to(:generated_passwords)
  end
end
require 'rails_helper'

RSpec.describe UserImportJob, type: :job do
  include ActiveJob::TestHelper

  let(:user_import) { create(:user_import) }

  it 'enqueues the job' do
    expect {
      UserImportJob.perform_later(user_import.id)
    }.to have_enqueued_job(UserImportJob)
  end

  it 'processes CSV file' do
    file = fixture_file_upload('spec/fixtures/files/users.csv', 'text/csv')
    user_import.file.attach(file)
    user_import.save!

    perform_enqueued_jobs do
      UserImportJob.perform_now(user_import.id)
    end

    user_import.reload
    expect(user_import.status).to eq('completed')
    expect(user_import.progress).to eq(user_import.total_rows)
  end

  it 'handles processing errors' do
    allow_any_instance_of(UserImportJob).to receive(:process_csv).and_raise(StandardError.new('Test error'))

    perform_enqueued_jobs do
      UserImportJob.perform_now(user_import.id)
    end

    user_import.reload
    expect(user_import.status).to eq('failed')
    expect(user_import.error_message).to eq('Test error')
  end

  describe 'broadcasting' do
    let(:file) { fixture_file_upload('spec/fixtures/files/users.csv', 'text/csv') }

    before do
      user_import.file.attach(file)
      user_import.save!
    end

    it 'broadcasts import started' do
      expect do
        UserImportJob.perform_now(user_import.id)
      end.to have_broadcasted_to("import_#{user_import.id}").with(
        hash_including(type: 'import_started')
      )
    end

    it 'broadcasts progress updates' do
      expect do
        UserImportJob.perform_now(user_import.id)
      end.to have_broadcasted_to("import_#{user_import.id}").with(
        hash_including(type: 'progress_update')
      ).at_least(:once)
    end

    it 'broadcasts import completed' do
      expect do
        UserImportJob.perform_now(user_import.id)
      end.to have_broadcasted_to("import_#{user_import.id}").with(
        hash_including(type: 'import_completed')
      )
    end

    it 'broadcasts to admin channel as well' do
      expect do
        UserImportJob.perform_now(user_import.id)
      end.to have_broadcasted_to("admin_imports").at_least(:once)
    end
  end
end
