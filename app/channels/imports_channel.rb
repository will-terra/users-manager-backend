# WebSocket channel for real-time user import status updates
# Allows admin users to subscribe to specific import progress or all imports
class ImportsChannel < ApplicationCable::Channel
  def subscribed
    # Only admins can subscribe to import updates
    return reject unless current_user&.admin?

    if params[:import_id]
      # Subscribe to specific import updates
      import = UserImport.find_by(id: params[:import_id])
      return reject unless import

      stream_from "import_#{import.id}"
      transmit_current_import_status(import)
    else
      # Subscribe to all import updates
      stream_from "admin_imports"
    end
  end

  def unsubscribed
    # Channel automatically stops streaming on unsubscribe
  end

  # Allows clients to request current import status
  def request_import_status
    if params[:import_id]
      import = UserImport.find_by(id: params[:import_id])
      transmit_current_import_status(import) if import
    end
  end

  private

  # Transmit import status update to subscribed clients
  def transmit_current_import_status(import)
    transmit({
      type: "import_status",
      data: import_status_data(import)
    })
  end

  # Build import status data structure for transmission
  def import_status_data(import)
    {
      id: import.id,
      status: import.status,
      progress: import.progress,
      total_rows: import.total_rows,
      percentage: import.percentage,
      error_message: import.error_message,
      created_at: import.created_at.iso8601,
      updated_at: import.updated_at.iso8601,
      file_name: import.file.filename.to_s,
      user: {
        id: import.user.id,
        full_name: import.user.full_name
      }
    }
  end
end
