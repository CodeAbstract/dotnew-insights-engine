class PageView < ApplicationRecord
  belongs_to :visit, counter_cache: true
  
  validates :path, presence: true
  validates :viewed_at, presence: true
  
  scope :of_path, ->(path) { where(path: path) }
  scope :most_viewed, -> { group(:path).order('count_all DESC').count }
  scope :recent, -> { order(viewed_at: :desc) }
  
  def self.track(visit, path)
    create!(
      visit: visit,
      path: path,
      viewed_at: Time.current
    )
  end
end