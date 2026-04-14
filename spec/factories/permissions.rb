FactoryBot.define do
  factory :permission do
    sequence(:resource) { |n| "resource_#{n}" }
    sequence(:action) { |n| "action_#{n}" }
    description { Faker::Lorem.sentence }
    metadata { {} }
  end
end
