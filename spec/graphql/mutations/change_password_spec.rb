require 'rails_helper'

RSpec.describe 'ChangePassword mutation', type: :graphql do
  let(:user) { create(:user, password: 'SecurePassword1@', password_confirmation: 'SecurePassword1@') }

  let(:mutation) do
    <<~GRAPHQL
      mutation ChangePassword($currentPassword: String!, $newPassword: String!) {
        changePassword(input: { currentPassword: $currentPassword, newPassword: $newPassword }) {
          success
          message
          user { id email }
          errors { message code field }
        }
      }
    GRAPHQL
  end

  def run_mutation(current_password: 'SecurePassword1@', new_password: 'NewSecure1@', as: user)
    execute_graphql(
      query: mutation,
      variables: { currentPassword: current_password, newPassword: new_password },
      user: as
    )
  end

  describe 'successful password change' do
    it 'changes the password and returns success' do
      result = run_mutation(new_password: 'NewSecure1@')

      expect(gql_errors(result)).to be_nil
      data = gql_data(result)['changePassword']
      expect(data['success']).to be true
      expect(data['message']).to eq('Password changed successfully. Please login again.')
      expect(data['user']).to be_present
      expect(data['errors']).to be_empty
    end

    it 'invalidates existing sessions by updating tokens_valid_after' do
      run_mutation(new_password: 'NewSecure1@')
      expect(user.reload.tokens_valid_after).to be_present
    end

    it 'allows login with new password' do
      run_mutation(new_password: 'NewSecure1@')
      expect(user.reload.authenticate('NewSecure1@')).to be_truthy
    end
  end

  describe 'wrong current password' do
    it 'returns failure for incorrect current password' do
      result = run_mutation(current_password: 'WrongPassword1@')

      data = gql_data(result)['changePassword']
      expect(data['success']).to be false
      expect(data['message']).to eq('Current password is incorrect')
      expect(data['errors'].first['code']).to eq('INVALID_CREDENTIALS')
    end
  end

  describe 'new password too weak' do
    it 'returns failure for password without special character' do
      result = run_mutation(new_password: 'NoSpecial1Ch')

      data = gql_data(result)['changePassword']
      expect(data['success']).to be false
      expect(data['errors']).to be_present
    end

    it 'returns failure for short password' do
      result = run_mutation(new_password: 'Sh1@')

      data = gql_data(result)['changePassword']
      expect(data['success']).to be false
    end
  end

  describe 'unauthenticated user' do
    it 'raises an authentication error when no user is provided' do
      result = execute_graphql(
        query: mutation,
        variables: { currentPassword: 'SecurePassword1@', newPassword: 'NewSecure1@' },
        user: nil
      )

      expect(gql_errors(result)).to be_present
    end
  end
end
