FactoryBot.define do
  factory :page_view do
    association :visit
    path { "/#{Faker::Lorem.word}" }
    viewed_at { Time.current }
  end
end 