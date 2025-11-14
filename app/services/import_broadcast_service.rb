# Service to broadcast user import updates to connected WebSocket clients
class ImportBroadcastService
  # Broadcast updated import list with pending count and recent imports
  def self.broadcast_import_list_update
    pending_imports = UserImport.where(status: [ "pending", "processing" ]).count
    recent_imports = UserImport.order(created_at: :desc).limit(5)

    ActionCable.server.broadcast(
      "admin_imports",
      {
        type: "imports_list_updated",
        data: {
          pending_imports: pending_imports,
          recent_imports: recent_imports.map do |import|
            {
              id: import.id,
              status: import.status,
              file_name: import.file.filename.to_s,
              created_at: import.created_at.iso8601,
              percentage: import.percentage
            }
          end
        }
      }
    )
  end

  # Broadcast notification when a new import is created
  def self.broadcast_import_created(import)
    ActionCable.server.broadcast(
      "admin_imports",
      {
        type: "import_created",
        data: {
          id: import.id,
          status: import.status,
          file_name: import.file.filename.to_s,
          created_at: import.created_at.iso8601,
          user: {
            id: import.user.id,
            full_name: import.user.full_name
          }
        }
      }
    )
  end
end
