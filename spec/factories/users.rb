FactoryBot.define do
  factory :user do
    first_name { Faker::Name.first_name.gsub(/[^a-zA-ZÀ-ÿ\s'-]/, '') }
    last_name  { Faker::Name.last_name.gsub(/[^a-zA-ZÀ-ÿ\s'-]/, '') }
    sequence(:email) { |n| "user#{n}@example.com" }
    password { 'SecurePassword1@' }
    password_confirmation { 'SecurePassword1@' }

    # skip after_create callback that tries to assign_default_role via DB
    after(:build) do |user|
      # ensure the Role 'user' exists so after_create callback doesn't fail
      Role.find_or_create_by(name: 'user') do |r|
        r.description = 'Default user role'
        r.system_role = true
      end
    end

    trait :admin do
      after(:create) do |user|
        admin_role = Role.find_or_create_by(name: 'admin') do |r|
          r.description = 'Administrator role'
          r.system_role = true
        end
        user.user_roles.find_or_create_by(role: admin_role) do |ur|
          ur.granted_at = Time.current
        end
      end
    end

    trait :without_roles do
      after(:create) do |user|
        user.user_roles.destroy_all
      end
    end
  end
end
