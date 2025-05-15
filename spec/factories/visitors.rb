FactoryBot.define do
  factory :visitor do
    uuid { SecureRandom.uuid }
    ip_address { Faker::Internet.ip_v4_address }
    user_agent { Faker::Internet.user_agent }
    first_visit_at { Time.current }
  end
end 