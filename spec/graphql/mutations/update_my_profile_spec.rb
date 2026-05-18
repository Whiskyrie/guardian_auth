require 'rails_helper'

RSpec.describe 'UpdateMyProfile mutation', type: :graphql do
  let(:user) { create(:user, first_name: 'Alice', last_name: 'Smith') }

  let(:mutation) do
    <<~GRAPHQL
      mutation UpdateMyProfile($input: UserInput!) {
        updateMyProfile(input: { input: $input }) {
          success
          message
          user { id email firstName lastName }
          errors { message code field }
        }
      }
    GRAPHQL
  end

  def run_mutation(input:, as: user)
    execute_graphql(query: mutation, variables: { input: input }, user: as)
  end

  describe 'successful profile update' do
    it 'updates first and last name' do
      result = run_mutation(input: { firstName: 'Bob', lastName: 'Jones' })
      data = gql_data(result)['updateMyProfile']

      expect(gql_errors(result)).to be_nil
      expect(data['success']).to be true
      expect(data['message']).to eq('Profile updated successfully')
      expect(data['user']['firstName']).to eq('Bob')
      expect(data['user']['lastName']).to eq('Jones')
    end

    it 'updates email' do
      result = run_mutation(input: { email: 'new@example.com' })
      data = gql_data(result)['updateMyProfile']

      expect(data['success']).to be true
      expect(user.reload.email).to eq('new@example.com')
    end
  end

  describe 'role change attempt' do
    it 'rejects role change on own profile' do
      result = run_mutation(input: { role: 'ADMIN' })
      data = gql_data(result)['updateMyProfile']

      expect(data['success']).to be false
      expect(data['message']).to eq('Cannot change your own role')
      expect(data['errors'].first['code']).to eq('INSUFFICIENT_PERMISSIONS')
    end
  end

  describe 'unauthenticated user' do
    it 'raises an execution error' do
      result = run_mutation(input: { firstName: 'Bob' }, as: nil)

      # authenticate! raises GraphQL::ExecutionError which propagates (no rescue in mutation)
      expect(gql_errors(result)).to be_present
      expect(gql_data(result)['updateMyProfile']).to be_nil
    end
  end

  describe 'invalid input' do
    it 'returns validation error for invalid email format' do
      result = run_mutation(input: { email: 'not-an-email' })
      data = gql_data(result)['updateMyProfile']

      expect(data['success']).to be false
      expect(data['errors']).to be_present
    end

    it 'returns validation error for name too short' do
      result = run_mutation(input: { firstName: 'X' })
      data = gql_data(result)['updateMyProfile']

      expect(data['success']).to be false
      expect(data['errors']).to be_present
    end
  end
end
