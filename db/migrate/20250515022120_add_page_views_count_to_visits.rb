class AddPageViewsCountToVisits < ActiveRecord::Migration[8.0]
  def change
    add_column :visits, :page_views_count, :integer, default: 0, null: false
  end
end 