require 'rails_helper'

RSpec.describe 'DeleteUser mutation', type: :graphql do
  let(:admin) { create(:user, :admin) }
  let(:target_user) { create(:user) }

  let(:mutation) do
    <<~GRAPHQL
      mutation DeleteUser($id: ID!) {
        deleteUser(input: { id: $id }) {
          success
          message
          errors { message code }
        }
      }
    GRAPHQL
  end

  def run_mutation(id: target_user.id.to_s, as: admin)
    execute_graphql(query: mutation, variables: { id: id }, user: as)
  end

  describe 'admin deletes a user' do
    it 'deletes the user and returns success' do
      result = run_mutation
      data = gql_data(result)['deleteUser']

      expect(gql_errors(result)).to be_nil
      expect(data['success']).to be true
      expect(data['message']).to include(target_user.email)
      expect(User.exists?(target_user.id)).to be false
    end
  end

  describe 'admin tries to delete themselves' do
    it 'rejects self-deletion' do
      result = run_mutation(id: admin.id.to_s)
      data = gql_data(result)['deleteUser']

      # authorize! raises GraphQL::ExecutionError, caught by rescue StandardError
      expect(data['success']).to be false
      expect(User.exists?(admin.id)).to be true
    end
  end

  describe 'non-admin user' do
    it 'rejects deletion attempt' do
      regular_user = create(:user)
      result = run_mutation(as: regular_user)
      data = gql_data(result)['deleteUser']

      # authorize! raises GraphQL::ExecutionError, caught by rescue StandardError
      expect(data['success']).to be false
      expect(User.exists?(target_user.id)).to be true
    end
  end

  describe 'unauthenticated' do
    it 'returns an error' do
      result = run_mutation(as: nil)
      data = gql_data(result)['deleteUser']

      # authenticate! raises GraphQL::ExecutionError, caught by rescue StandardError
      expect(data['success']).to be false
    end
  end

  describe 'user not found' do
    it 'returns not found error' do
      result = run_mutation(id: '0')
      data = gql_data(result)['deleteUser']

      expect(data['success']).to be false
      expect(data['message']).to eq('User not found')
      expect(data['errors'].first['code']).to eq('RESOURCE_NOT_FOUND')
    end
  end
end
