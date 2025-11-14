class RemoveGeneratedPasswordsFromUserImports < ActiveRecord::Migration[8.0]
  def change
    if column_exists?(:user_imports, :generated_passwords)
      remove_column :user_imports, :generated_passwords, :text
    end
  end
end
