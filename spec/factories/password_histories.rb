FactoryBot.define do
  factory :password_history do
    association :user
    password_digest { BCrypt::Password.create('OldPass1!') }
  end
end
