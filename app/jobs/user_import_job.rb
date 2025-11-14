# Background job to process bulk user imports from CSV/Excel files
# Handles file parsing, user creation, error tracking, and real-time progress broadcasting
class UserImportJob < ApplicationJob
  queue_as :default

  BATCH_SIZE = 10

  def perform(user_import_id)
    @user_import = UserImport.find(user_import_id)
    @user_import.mark_as_processing

    file = @user_import.file.download
    extension = File.extname(@user_import.file.filename.to_s)

    # Route to appropriate parser based on file type
    case extension.downcase
    when ".csv"
      process_csv(file)
    when ".xlsx", ".xls"
      process_excel(file)
    else
      @user_import.mark_as_failed(StandardError.new("Unsupported file type: #{extension}"))
    end
  rescue => e
    @user_import.mark_as_failed(e)
    broadcast_final_status
  end

  private

  # Parse and process CSV file
  def process_csv(file)
    require "csv"
    rows = CSV.parse(file, headers: true)
    @user_import.update(total_rows: rows.size)
    broadcast_initial_status

    process_rows_in_batches(rows)

    @user_import.mark_as_completed
    broadcast_final_status
  end

  # Parse and process Excel file (.xlsx, .xls)
  def process_excel(file)
    require "roo"
    spreadsheet = Roo::Spreadsheet.open(StringIO.new(file))
    sheet = spreadsheet.sheet(0)
    rows = sheet.parse(headers: true)
    @user_import.update(total_rows: rows.size)
    broadcast_initial_status

    process_rows_in_batches(rows)

    @user_import.mark_as_completed
    broadcast_final_status
  end

  # Process rows in configurable batches with error tracking and progress broadcasting
  def process_rows_in_batches(rows)
    successful_imports = 0
    failed_imports = 0
    errors = []

    rows.each_slice(BATCH_SIZE).with_index do |batch, batch_index|
      batch.each_with_index do |row, index_in_batch|
        global_index = (batch_index * BATCH_SIZE) + index_in_batch

        begin
          create_user_from_row(row)
          successful_imports += 1
        rescue => e
          failed_imports += 1
          errors << "Row #{global_index + 2}: #{e.message}"
        end

        @user_import.update_progress(global_index + 1)
      end

      broadcast_progress(successful_imports, failed_imports, errors.last(5))

      sleep(0.1) if Rails.env.development?
    end

    @user_import.update(
      progress: rows.size,
      error_message: errors.any? ? "Completed with #{failed_imports} errors. First few: #{errors.first(3).join('; ')}" : nil
    )
  end

  # Create or update a user from a single CSV/Excel row with validation
  # Sends welcome email with password immediately for new users (passwords are never stored)
  def create_user_from_row(row)
    user_attributes = {
      full_name: row["full_name"] || row["name"] || row["Full Name"] || row["Nome Completo"],
      email: row["email"] || row["Email"] || row["E-mail"],
      role: (row["role"] || row["Role"] || "user").downcase
    }

    raise "Full name is required" if user_attributes[:full_name].blank?
    raise "Email is required" if user_attributes[:email].blank?
    raise "Invalid email format" unless URI::MailTo::EMAIL_REGEXP.match?(user_attributes[:email])

    # Find existing user by email or initialize a new one
    user = User.find_or_initialize_by(email: user_attributes[:email])

    # Update attributes (email remains the same)
    user.full_name = user_attributes[:full_name]
    user.role = user_attributes[:role]

    # Track if this is a new user to send welcome email
    is_new_user = user.new_record?

    # Handle password: use CSV password if provided, or generate for new users
    csv_password = row["password"] || row["Password"]
    password_for_email = nil

    if csv_password.present?
      # Update password if explicitly provided in CSV
      # Note: user.password= is provided by Devise and automatically hashes the password
      # using bcrypt before storing. The plaintext password is never persisted to the database.
      user.password = csv_password # lgtm[rb/clear-text-storage-sensitive-data]
      user.password_confirmation = csv_password # lgtm[rb/clear-text-storage-sensitive-data]
      password_for_email = csv_password if is_new_user
    elsif is_new_user
      # Generate password only for new users when not provided
      password = SecureRandom.hex(8)
      # Note: user.password= is provided by Devise and automatically hashes the password
      # using bcrypt before storing. The plaintext password is never persisted to the database.
      user.password = password # lgtm[rb/clear-text-storage-sensitive-data]
      user.password_confirmation = password # lgtm[rb/clear-text-storage-sensitive-data]
      password_for_email = password
    end

    # Handle avatar URL if provided
    if row["avatar_url"].present?
      user.avatar_url = row["avatar_url"]
    end

    user.save!

    # Send welcome email immediately with password (never store the password)
    if is_new_user && password_for_email.present?
      UserMailer.welcome_email_with_password(user, password_for_email).deliver_later
    end
  end

  # Broadcast initial import started event to subscribers
  def broadcast_initial_status
    ActionCable.server.broadcast(
      "import_#{@user_import.id}",
      {
        type: "import_started",
        data: import_status_data
      }
    )

    ActionCable.server.broadcast(
      "admin_imports",
      {
        type: "import_started",
        data: import_status_data.merge(channel: "import_#{@user_import.id}")
      }
    )
  end

  # Broadcast progress updates to subscribers (throttled for admin channel)
  def broadcast_progress(successful_imports, failed_imports, recent_errors)
    ActionCable.server.broadcast(
      "import_#{@user_import.id}",
      {
        type: "progress_update",
        data: import_status_data.merge(
          successful_imports: successful_imports,
          failed_imports: failed_imports,
          recent_errors: recent_errors
        )
      }
    )

    current_percentage = @user_import.percentage
    if current_percentage % 10 == 0 || current_percentage == 100
      ActionCable.server.broadcast(
        "admin_imports",
        {
          type: "progress_update",
          data: import_status_data.merge(
            successful_imports: successful_imports,
            failed_imports: failed_imports,
            channel: "import_#{@user_import.id}"
          )
        }
      )
    end
  end

  # Broadcast final import completed/failed event to subscribers
  def broadcast_final_status
    ActionCable.server.broadcast(
      "import_#{@user_import.id}",
      {
        type: "import_completed",
        data: import_status_data
      }
    )

    ActionCable.server.broadcast(
      "admin_imports",
      {
        type: "import_completed",
        data: import_status_data.merge(channel: "import_#{@user_import.id}")
      }
    )
  end

  # Build status data structure for broadcasting
  def import_status_data
    {
      id: @user_import.id,
      status: @user_import.status,
      progress: @user_import.progress,
      total_rows: @user_import.total_rows,
      percentage: @user_import.percentage,
      error_message: @user_import.error_message,
      created_at: @user_import.created_at.iso8601,
      file_name: @user_import.file.filename.to_s
    }
  end
end
