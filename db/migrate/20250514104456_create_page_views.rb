class CreatePageViews < ActiveRecord::Migration[8.0]
  def change
    create_table :page_views do |t|
      t.references :visit, null: false, foreign_key: true
      t.string :path
      t.datetime :viewed_at

      t.timestamps
    end
  end
end
