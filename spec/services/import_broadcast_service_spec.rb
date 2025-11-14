require 'rails_helper'

RSpec.describe ImportBroadcastService, type: :service do
  describe '.broadcast_import_created' do
    it 'broadcasts import created event' do
      import = build(:user_import)
      import.save(validate: false) # Save without triggering validations or callbacks
      import.reload

      expect(ActionCable.server).to receive(:broadcast).with(
        'admin_imports',
        hash_including(type: 'import_created')
      )

      ImportBroadcastService.broadcast_import_created(import)
    end
  end

  describe '.broadcast_import_list_update' do
    it 'broadcasts imports list updated event' do
      expect(ActionCable.server).to receive(:broadcast).with(
        'admin_imports',
        hash_including(type: 'imports_list_updated')
      )

      ImportBroadcastService.broadcast_import_list_update
    end
  end
end
