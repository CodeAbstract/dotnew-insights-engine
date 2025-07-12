class AddSiteUrlAndAppNameToVisits < ActiveRecord::Migration[8.0]
  def change
    add_column :visits, :site_url, :string
    add_column :visits, :app_name, :string
  end
end
