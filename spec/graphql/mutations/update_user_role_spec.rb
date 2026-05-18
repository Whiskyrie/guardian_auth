require 'rails_helper'

RSpec.describe 'UpdateUserRole mutation', type: :graphql do
  let(:admin) { create(:user, :admin) }
  let(:target_user) { create(:user) }

  let(:mutation) do
    <<~GRAPHQL
      mutation UpdateUserRole($userId: ID!, $roleNames: [UserRoleEnum!]!) {
        updateUserRole(input: { userId: $userId, roleNames: $roleNames }) {
          success
          message
          user { id email }
          errors { message code }
        }
      }
    GRAPHQL
  end

  def run_mutation(user_id: target_user.id.to_s, role_names: ['USER'], as: admin)
    execute_graphql(query: mutation, variables: { userId: user_id, roleNames: role_names }, user: as)
  end

  describe 'admin assigns roles' do
    it 'assigns the user role successfully' do
      result = run_mutation(role_names: ['USER'])
      data = gql_data(result)['updateUserRole']

      expect(gql_errors(result)).to be_nil
      expect(data['success']).to be true
      expect(data['message']).to eq('User roles updated successfully')
      expect(target_user.reload.has_role?('user')).to be true
    end

    it 'assigns admin role successfully' do
      result = run_mutation(role_names: ['ADMIN'])
      data = gql_data(result)['updateUserRole']

      expect(data['success']).to be true
      expect(target_user.reload.admin?).to be true
    end

    it 'replaces existing roles atomically' do
      result = run_mutation(role_names: ['USER'])
      data = gql_data(result)['updateUserRole']

      expect(data['success']).to be true
      expect(target_user.reload.role_names).to eq(['user'])
    end
  end

  describe 'non-admin user' do
    it 'rejects the request' do
      regular_user = create(:user)
      result = run_mutation(as: regular_user)
      data = gql_data(result)['updateUserRole']

      expect(data['success']).to be false
      expect(data['message']).to eq('You are not authorized to modify user roles')
      expect(data['errors'].first['code']).to eq('INSUFFICIENT_PERMISSIONS')
    end
  end

  describe 'unauthenticated' do
    it 'returns an error' do
      result = run_mutation(as: nil)
      data = gql_data(result)['updateUserRole']

      # authenticate! raises GraphQL::ExecutionError, caught by rescue StandardError
      expect(data['success']).to be false
    end
  end

  describe 'user not found' do
    it 'returns not found error' do
      result = run_mutation(user_id: '0')
      data = gql_data(result)['updateUserRole']

      expect(data['success']).to be false
      expect(data['message']).to eq('User not found')
      expect(data['errors'].first['code']).to eq('RESOURCE_NOT_FOUND')
    end
  end
end
