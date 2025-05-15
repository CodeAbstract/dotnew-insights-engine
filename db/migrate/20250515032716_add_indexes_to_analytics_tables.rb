class AddIndexesToAnalyticsTables < ActiveRecord::Migration[8.0]
  def change
    # Add indexes to visits table (if they don't exist)
    add_index :visits, :entered_at unless index_exists?(:visits, :entered_at)
    add_index :visits, :device_type unless index_exists?(:visits, :device_type)
    add_index :visits, :source_type unless index_exists?(:visits, :source_type)
    add_index :visits, :country_code unless index_exists?(:visits, :country_code)
    add_index :visits, :bounced unless index_exists?(:visits, :bounced)
    
    # Add indexes to page_views table (if they don't exist)
    add_index :page_views, :path unless index_exists?(:page_views, :path)
    add_index :page_views, :viewed_at unless index_exists?(:page_views, :viewed_at)
    add_index :page_views, :visit_id unless index_exists?(:page_views, :visit_id)
    
    # Add compound indexes for common queries (if they don't exist)
    add_index :visits, [:entered_at, :bounced], name: 'index_visits_on_entered_at_and_bounced' unless index_exists?(:visits, [:entered_at, :bounced])
    add_index :visits, [:entered_at, :country_code], name: 'index_visits_on_entered_at_and_country_code' unless index_exists?(:visits, [:entered_at, :country_code])
    add_index :page_views, [:viewed_at, :path], name: 'index_page_views_on_viewed_at_and_path' unless index_exists?(:page_views, [:viewed_at, :path])
  end
end
