FactoryBot.define do
  factory :session do
    association :user
    jti { SecureRandom.uuid }
    ip_address { '127.0.0.1' }
    user_agent { 'Mozilla/5.0 (RSpec)' }
    expires_at { 24.hours.from_now }
    revoked_at { nil }
    revoked_reason { nil }

    trait :revoked do
      revoked_at { Time.current }
      revoked_reason { 'user_revoked' }
    end

    trait :expired do
      expires_at { 1.hour.ago }
    end
  end
end
