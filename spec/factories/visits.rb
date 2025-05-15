FactoryBot.define do
  factory :visit do
    association :visitor
    page_path { "/#{Faker::Lorem.word}" }
    referrer { Faker::Internet.url }
    device_type { %w[desktop mobile tablet].sample }
    source_type { %w[direct search referral social].sample }
    country_code { Faker::Address.country_code }
    region { Faker::Address.state }
    city { Faker::Address.city }
    entered_at { Time.current }
    exited_at { nil }
    duration { nil }
    page_views_count { 0 }

    trait :completed do
      exited_at { entered_at + 5.minutes }
      duration { 300 } # 5 minutes in seconds
    end

    trait :bounced do
      page_views_count { 1 }
      completed
    end

    trait :engaged do
      page_views_count { rand(2..10) }
      completed
    end
  end
end 