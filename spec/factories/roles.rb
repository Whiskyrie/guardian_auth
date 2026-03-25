FactoryBot.define do
  factory :role do
    sequence(:name) { |n| "role_#{n}" }
    description { Faker::Lorem.sentence }
    system_role { false }

    trait :admin do
      name { 'admin' }
      description { 'Administrator role' }
      system_role { true }
    end

    trait :user do
      name { 'user' }
      description { 'Default user role' }
      system_role { true }
    end
  end
end
