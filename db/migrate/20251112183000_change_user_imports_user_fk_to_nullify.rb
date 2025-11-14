class ChangeUserImportsUserFkToNullify < ActiveRecord::Migration[7.0]
  def up
    # Allow null on user_id so ON DELETE SET NULL will work
    change_column_null :user_imports, :user_id, true

    # Remove existing foreign key and re-add with ON DELETE SET NULL
    remove_foreign_key :user_imports, :users
    add_foreign_key :user_imports, :users, on_delete: :nullify
  end

  def down
    # Restore previous constraint: make user_id not null and add FK without ON DELETE
    remove_foreign_key :user_imports, :users

    # Ensure no nulls exist before making column NOT NULL
    execute <<-SQL.squish
      UPDATE user_imports SET user_id = 0 WHERE user_id IS NULL;
    SQL

    change_column_null :user_imports, :user_id, false
    add_foreign_key :user_imports, :users
  end
end
