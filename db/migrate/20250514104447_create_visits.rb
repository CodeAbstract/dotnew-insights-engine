class CreateVisits < ActiveRecord::Migration[8.0]
  def change
    create_table :visits do |t|
      t.references :visitor, null: false, foreign_key: true
      t.string :page_path
      t.string :referrer
      t.string :device_type
      t.string :source_type
      t.string :country_code
      t.string :region
      t.string :city
      t.integer :duration
      t.boolean :bounced
      t.datetime :entered_at
      t.datetime :exited_at

      t.timestamps
    end
  end
end
