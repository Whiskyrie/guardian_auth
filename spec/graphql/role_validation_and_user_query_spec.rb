require 'rails_helper'

RSpec.describe 'Role validation and user query', type: :graphql do
  describe 'enum validation for role arguments' do
    it 'rejects invalid role values before resolver execution' do
      mutation = <<~GRAPHQL
        mutation UpdateUserByEmail($input: UpdateUserByEmailInput!) {
          updateUserByEmail(input: $input) {
            user { id }
            errors { message code field }
          }
        }
      GRAPHQL

      result = execute_graphql(
        query: mutation,
        variables: {
          input: {
            email: 'someone@example.com',
            input: {
              role: 'NOT_A_REAL_ROLE'
            }
          }
        }
      )

      expect(gql_errors(result)).to be_present
      expect(gql_errors(result).first['message']).to match(/UserRoleEnum|one of/i)
    end
  end

  describe 'user query resolver' do
    it 'returns a user when requester is admin' do
      admin = create(:user, :admin)
      target_user = create(:user)

      query = <<~GRAPHQL
        query FindUser($id: ID!) {
          user(id: $id) {
            id
            email
            role
            roles
          }
        }
      GRAPHQL

      result = execute_graphql(
        query: query,
        variables: { id: target_user.id.to_s },
        user: admin
      )

      expect(gql_errors(result)).to be_nil
      user_data = gql_data(result).fetch('user')

      expect(user_data['id']).to eq(target_user.id.to_s)
      expect(user_data['email']).to eq(target_user.email)
      expect(user_data['role']).to eq('USER')
      expect(user_data['roles']).to include('USER')
    end
  end
end
