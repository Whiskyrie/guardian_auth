FactoryBot.define do
  factory :audit_log do
    association :user
    action { 'login' }
    resource { 'User' }
    resource_id { user&.id.to_s }
    result { 'success' }
    metadata { {} }
  end
end
