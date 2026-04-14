FactoryBot.define do
  factory :password_reset_token do
    association :user
    token_hash { Digest::SHA256.hexdigest(SecureRandom.uuid) }
    expires_at { 1.hour.from_now }
    ip_address { '127.0.0.1' }
    user_agent { 'RSpec' }
    used { false }
  end
end
