FactoryBot.define do
  factory :token_blacklist do
    association :user
    jti { SecureRandom.uuid }
    expires_at { 24.hours.from_now }
    reason { 'logout' }
  end
end
