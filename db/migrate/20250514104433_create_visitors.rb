class CreateVisitors < ActiveRecord::Migration[8.0]
  def change
    create_table :visitors do |t|
      t.string :uuid
      t.string :ip_address
      t.string :user_agent
      t.datetime :first_visit_at

      t.timestamps
    end
    add_index :visitors, :uuid, unique: true
  end
end
