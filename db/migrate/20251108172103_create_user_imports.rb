class CreateUserImports < ActiveRecord::Migration[8.0]
  def change
    create_table :user_imports do |t|
      t.references :user, null: false, foreign_key: true
      t.string :status, null: false, default: 'pending'
      t.integer :progress, default: 0
      t.integer :total_rows, default: 0
      t.text :error_message

      t.timestamps
    end
  end
end
