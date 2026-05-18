require 'rails_helper'

RSpec.describe 'UpdateUserByEmail mutation', type: :graphql do
  let(:admin) { create(:user, :admin) }
  let(:target_user) { create(:user, first_name: 'Alice', last_name: 'Smith') }

  let(:mutation) do
    <<~GRAPHQL
      mutation UpdateUserByEmail($email: String!, $input: UserInput!) {
        updateUserByEmail(input: { email: $email, input: $input }) {
          success
          message
          user { id email firstName lastName }
          errors { message code }
        }
      }
    GRAPHQL
  end

  def run_mutation(email: target_user.email, input: {}, as: admin)
    execute_graphql(query: mutation, variables: { email: email, input: input }, user: as)
  end

  describe 'admin updating user by email' do
    it 'updates user fields successfully' do
      result = run_mutation(input: { firstName: 'Carol' })
      data = gql_data(result)['updateUserByEmail']

      expect(gql_errors(result)).to be_nil
      expect(data['success']).to be true
      expect(data['user']['firstName']).to eq('Carol')
    end

    it 'changes role when requested' do
      result = run_mutation(input: { role: 'ADMIN' })
      data = gql_data(result)['updateUserByEmail']

      expect(data['success']).to be true
      expect(target_user.reload.admin?).to be true
    end
  end

  describe 'user not found' do
    it 'returns not found error' do
      result = run_mutation(email: 'nobody@example.com')
      data = gql_data(result)['updateUserByEmail']

      expect(data['success']).to be false
      expect(data['message']).to eq('User not found')
      expect(data['errors'].first['code']).to eq('RESOURCE_NOT_FOUND')
    end
  end

  describe 'unauthorized user' do
    it 'rejects update of another user by regular user' do
      other_user = create(:user)
      result = run_mutation(as: other_user)

      # authorize! raises GraphQL::ExecutionError which propagates (no rescue in mutation)
      expect(gql_errors(result)).to be_present
      expect(gql_data(result)['updateUserByEmail']).to be_nil
    end
  end

  describe 'role change by non-admin' do
    it 'returns error when non-admin attempts role change' do
      # target_user can update their own profile, but not change roles
      result = run_mutation(input: { role: 'ADMIN' }, as: target_user)
      data = gql_data(result)['updateUserByEmail']

      expect(data['success']).to be false
      expect(data['errors'].first['code']).to eq('INSUFFICIENT_PERMISSIONS')
    end
  end
end
